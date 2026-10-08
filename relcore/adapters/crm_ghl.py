"""CRM writes to GoHighLevel with relsend's own private integration token (RELSEND_GHL_TOKEN; scopes
opportunities.write and contacts.write). The agent's GHL token is read-only and cannot reach these endpoints.

stage: PUT /opportunities/{id} {pipelineId, pipelineStageId} (Version 2021-07-28). Setting the same stage twice
       changes nothing, so a timeout is retried rather than halted.
note:  POST /contacts/{contactId}/notes {body} (Version 2021-07-28). A second note would be a duplicate, so a
       timeout after the request went out is an unknown outcome: the sender halts and the owner checks.
The contract script confirms both shapes against a test record before the channel goes live."""
from __future__ import annotations

from . import SendError
from ..http import HTTPError, request

BASE = "https://services.leadconnectorhq.com"
VERSION = "2021-07-28"


class GhlCrm:
    name = "ghl-crm"

    def __init__(self, env: dict):
        self.token = env.get("RELSEND_GHL_TOKEN")
        if not self.token:
            raise SendError("relsend has no GHL token configured")

    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self.token}", "Version": VERSION}

    def send(self, row: dict) -> dict:
        p = row.get("crm") or {}
        if p.get("op") == "stage":
            try:
                out = request("PUT", f"{BASE}/opportunities/{p['opportunity_id']}", headers=self._headers(),
                              body={"pipelineId": p["pipeline_id"], "pipelineStageId": p["stage_id"]}, timeout=45)
            except HTTPError as err:
                if err.accepted_maybe or err.status in (0, 429) or err.status >= 500:
                    raise SendError(f"stage update not confirmed: {err}", retry=True) from None  # idempotent: safe to repeat
                raise SendError(str(err)) from None
            opp = out.get("opportunity") or out
            return {"provider_msg_id": f"opportunity:{opp.get('id') or p['opportunity_id']}:{p['stage_id']}"}
        if p.get("op") == "note":
            try:
                out = request("POST", f"{BASE}/contacts/{p['contact_id']}/notes", headers=self._headers(),
                              body={"body": p["note"]}, timeout=45)
            except HTTPError as err:
                if err.accepted_maybe or err.status >= 500:
                    raise SendError(str(err), accepted_maybe=True) from None
                raise SendError(str(err), retry=err.status == 429) from None
            note = out.get("note") or out
            return {"provider_msg_id": f"note:{note.get('id') or 'accepted'}"}
        raise SendError(f"unknown CRM operation {p.get('op')}")

    def check(self, opportunity_id: str) -> dict:
        """Contract: read a test opportunity, then write its own current stage back (changes nothing)."""
        got = request("GET", f"{BASE}/opportunities/{opportunity_id}", headers=self._headers())
        opp = got.get("opportunity") or got
        request("PUT", f"{BASE}/opportunities/{opportunity_id}", headers=self._headers(),
                body={"pipelineId": opp["pipelineId"], "pipelineStageId": opp["pipelineStageId"]})
        return {"opportunity": opportunity_id, "pipeline_id": opp["pipelineId"], "stage_id": opp["pipelineStageId"]}
