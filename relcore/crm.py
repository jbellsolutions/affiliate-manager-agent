"""CRM write-back: the pipeline in your CRM moves when the relationship does, after the owner approves it.

The agent never writes to the CRM. When a partnership moves forward (a conversation stage, or a conversion that
the partner platform recorded), trp prepares a crm_update bundle. It goes the same way as a message: the owner
approves it in the approvals channel, relapprove signs it, and relsend writes it with its own CRM token.

    one partnership, up to two writes:
      stage  move the CRM opportunity to the pipeline stage mapped from relcore's stage (forward only)
      note   log the conversion on the CRM contact: how many the partner platform has recorded, and when

The map lives in the root-owned /etc/relcore/crm.json, read by all three users, written by none of them:

    {"provider": "ghl", "pipeline_id": "<GHL pipeline id>",
     "stages": {"contacted": "<stage id>", "replied": "...", "engaged": "...", "call_booked": "...",
                "planned": "...", "first_conversion": "...", "repeat": "..."},
     "notes": true}

Leave a stage out and relcore never moves an opportunity there. relapprove and relsend both check every write
against this map, so a bundle can only ever name the configured pipeline and its stages. Each partnership needs a
CRM opportunity id (the crm_opportunity_id column of an import), and a CRM contact id for notes (crm_contact_id).

    python3 -m relcore crm status      what would move, and what is already waiting for approval
    python3 -m relcore crm prepare     prepare the moves now (ingest also does this when crm.json says auto_prepare)
"""
from __future__ import annotations

import argparse
import json
import re

from . import clock, config

PIPELINE = ("contacted", "replied", "engaged", "call_booked", "planned", "first_conversion", "repeat")
CONVERSATION = {"contacted": 1, "replied": 2, "engaged": 3, "call_booked": 4, "planned": 5, "producing": 6}
LABEL = {"contacted": "Contacted", "replied": "Replied", "engaged": "Engaged", "call_booked": "Call booked",
         "planned": "Plan sent", "first_conversion": "First conversion", "repeat": "Repeat producer"}
OPS = ("stage", "note")
CRM_ID = re.compile(r"^[A-Za-z0-9_.:-]{1,80}$")
NOTE_MAX = 600


def settings(paths) -> dict | None:
    cfg = config.root_json(paths, "crm.json")
    if not cfg or not cfg.get("stages"):
        return None
    return cfg


def validate_message(m: dict, cfg: dict | None) -> list[str]:
    """Shared by relapprove (before the card is shown) and relsend (before it is queued and again before it runs)."""
    n = m.get("n")
    if not cfg:
        return [f"{n}: no CRM map is configured (/etc/relcore/crm.json)"]
    p = m.get("crm") or {}
    problems = []
    if p.get("op") not in OPS:
        problems.append(f"{n}: unknown CRM operation")
    if p.get("op") == "stage":
        if not CRM_ID.match(str(p.get("opportunity_id") or "")) or p.get("opportunity_id") != m.get("address"):
            problems.append(f"{n}: bad opportunity id")
        if p.get("pipeline_id") != cfg.get("pipeline_id"):
            problems.append(f"{n}: not the configured pipeline")
        if p.get("stage") not in PIPELINE or cfg["stages"].get(p.get("stage")) != p.get("stage_id"):
            problems.append(f"{n}: stage is not in the CRM map")
    if p.get("op") == "note":
        if not cfg.get("notes", True):
            problems.append(f"{n}: CRM notes are turned off")
        if not CRM_ID.match(str(p.get("contact_id") or "")) or p.get("contact_id") != m.get("address"):
            problems.append(f"{n}: bad contact id")
        note = p.get("note") or ""
        if not note.strip() or len(note) > NOTE_MAX or re.search("[–—]", note):
            problems.append(f"{n}: note must be 1 to {NOTE_MAX} characters, no dashes")
    if m.get("person_id") or m.get("first_touch") or m.get("reply_to"):
        problems.append(f"{n}: a CRM write is not a message to a person")
    return problems


# ---------------------------------------------------------------- trp side (no credentials)
def _slot(profile, name):
    v = profile["slots"].get(name)
    return v[0]["value"] if v else None


def reached(store, ps: str) -> str | None:
    """The furthest pipeline stage this partnership has reached: conversation stages from the cards, conversion
    stages from the system of record only (lifecycle)."""
    from . import lifecycle
    rank = CONVERSATION.get(store.entity(ps)["fields"].get("stage") or "new", 0)
    life = lifecycle.stage_of(store, ps)
    best = None
    for s in PIPELINE:
        if s in CONVERSATION and rank >= CONVERSATION[s]:
            best = s
        if s == "first_conversion" and life in ("first_conversion", "repeat"):
            best = s
        if s == "repeat" and life == "repeat":
            best = s
    return best


def _waiting(store, ps: str) -> bool:
    return bool(store.con.execute(
        "SELECT 1 FROM action_messages m JOIN actions a ON a.action_id=m.action_id WHERE m.partnership_id=? AND m.channel='crm' "
        "AND m.state IN ('prepared','approved','unknown') AND a.state NOT IN ('rejected','withdrawn','expired')", (ps,)).fetchone())


def due(store, cfg: dict | None = None) -> list[dict]:
    """What would be written now: forward stage moves and new conversions, for partnerships with a CRM id."""
    cfg = cfg if cfg is not None else settings(store.paths)
    if not cfg:
        return []
    out = []
    for ps in store.all_ids("partnership"):
        p = store.profile(ps)
        opp, contact = _slot(p, "crm_opportunity"), _slot(p, "crm_contact")
        if not opp and not contact:
            continue
        waiting = _waiting(store, ps)
        item = {"partnership_id": ps, "label": store.label(ps), "waiting": waiting, "writes": []}
        target = reached(store, ps)
        current = _slot(p, "crm_stage")
        allowed = [s for s in PIPELINE if s in cfg["stages"]]
        if target and opp:
            best = max((s for s in allowed if PIPELINE.index(s) <= PIPELINE.index(target)), key=PIPELINE.index, default=None)
            if best and (current not in PIPELINE or PIPELINE.index(best) > PIPELINE.index(current)):
                why = (f"the partner platform recorded {_slot(p, 'conversions')} conversions" if best in ("first_conversion", "repeat")
                       else f"the relationship is at {store.entity(ps)['fields'].get('stage')} on the cards")
                item["writes"].append({"op": "stage", "opportunity_id": opp, "pipeline_id": cfg.get("pipeline_id"),
                                       "stage": best, "stage_id": cfg["stages"][best], "from": current, "why": why})
        conversions = int(_slot(p, "conversions") or 0)
        logged = int(_slot(p, "crm_conversions") or 0)
        if contact and cfg.get("notes", True) and conversions > logged:
            last = _slot(p, "last_conversion")
            code = _slot(p, "code")
            note = (f"Conversion recorded on the partner platform for {store.label(ps)}: {conversions} in total"
                    + (f", the latest on {last}" if last else "") + (f" (code {code})" if code else "") + ". Logged by relcore.")
            item["writes"].append({"op": "note", "contact_id": contact, "note": note[:NOTE_MAX], "conversions": conversions})
        if item["writes"]:
            out.append(item)
    return out


def _body(label: str, w: dict) -> str:
    if w["op"] == "stage":
        was = f" (was {LABEL.get(w['from'], w['from'])})" if w.get("from") else ""
        return f"Move {label} to {LABEL[w['stage']]} in the CRM pipeline{was}. Why: {w['why']}."
    return f"Log a note on the CRM contact: {w['note']}"


def prepare(store, employee: str | None = None) -> dict:
    """One crm_update bundle for everything due and not already waiting. Signed like any message, never sent by trp."""
    from . import actions
    from .db import tx
    cfg = settings(store.paths)
    if not cfg:
        return {"action_id": None, "reason": "no CRM map (/etc/relcore/crm.json)"}
    if actions.stopped(store):
        raise PermissionError("external writes are stopped (kill switch): nothing can be prepared")
    items = [i for i in due(store, cfg) if not i["waiting"]]
    if not items:
        return {"action_id": None, "reason": "nothing to write"}
    bundle = actions._new_bundle(store, "crm_update", employee, None)
    n = 0
    for item in items:
        for w in item["writes"]:
            n += 1
            payload = {k: v for k, v in w.items() if k not in ("from", "why")}
            bundle["messages"].append({
                "n": n, "channel": "crm", "address": w.get("opportunity_id") or w.get("contact_id"), "subject": "",
                "body": _body(item["label"], w), "person_id": None, "partnership_id": item["partnership_id"],
                "first_touch": False, "consent_basis": None, "reply_to": None, "hook": w["op"], "template": f"crm-{w['op']}",
                "arm": None, "context_digest": None, "recipient": item["label"], "segment": None, "crm": payload})
    out = actions._write(store, bundle, {"rule": "partnerships whose CRM record is behind the cards", "picked": len(items),
                                         "held_out": 0, "skipped": {}}, [])
    with tx(store.con):
        for m in bundle["messages"]:
            store.con.execute("INSERT OR REPLACE INTO crm_writes VALUES (?,?,?,?)",
                              (bundle["action_id"], m["n"], m["partnership_id"], json.dumps(m["crm"], sort_keys=True)))
    return out


def payload(store, action_id: str, n: int) -> dict | None:
    row = store.con.execute("SELECT payload FROM crm_writes WHERE action_id=? AND n=?", (action_id, n)).fetchone()
    return json.loads(row["payload"]) if row else None


def record(store, ps: str, p: dict, at: str) -> None:
    """A CRM write relsend (or, on drafts-only installs, the human) confirmed. Recorded as record facts: no model
    can move the CRM stage on a card."""
    from .db import tx
    if p["op"] == "stage":
        store.remember(ps, facts=[{"slot": "crm_stage", "value": p["stage"]}], source="record",
                       source_ref=f"crm:stage:{p['opportunity_id']}:{p['stage']}", by="import", recorder="crm")
        line, ref = f"CRM pipeline moved to {LABEL.get(p['stage'], p['stage'])} (opportunity {p['opportunity_id']})", f"crm:moved:{p['stage']}"
    else:
        store.remember(ps, facts=[{"slot": "crm_conversions", "value": str(p.get("conversions") or 0)}], source="record",
                       source_ref=f"crm:note:{p['contact_id']}:{p.get('conversions')}", by="import", recorder="crm")
        line, ref = f"CRM note logged: {p.get('conversions')} conversions on record", f"crm:noted:{p.get('conversions')}"
    with tx(store.con):
        store._timeline(ps, line, f"{ref}:{at}")
    if store.render_enabled:
        store.vault.render_around({ps})


def auto(store) -> dict | None:
    cfg = settings(store.paths)
    if not cfg or not cfg.get("auto_prepare"):
        return None
    try:
        return prepare(store)
    except PermissionError as err:
        return {"action_id": None, "reason": str(err)}


def main(argv=None) -> int:
    from .store import Store
    ap = argparse.ArgumentParser(prog="relcore crm")
    ap.add_argument("command", choices=["status", "prepare"])
    a = ap.parse_args(argv)
    store = Store(config.resolve())
    if a.command == "status":
        print(json.dumps({"configured": bool(settings(store.paths)), "due": due(store), "at": clock.iso()}, indent=1))
    else:
        print(json.dumps(prepare(store, employee="owner"), indent=1))
    return 0


def _t_crm_status(srv):
    return {"configured": bool(settings(srv.store.paths)), "due": due(srv.store)}


def _t_crm_prepare(srv):
    return prepare(srv.store, employee=srv.employee)


MCP_TOOLS = [
    {"name": "rel_crm_status", "read": True, "handler": _t_crm_status,
     "description": "What the CRM pipeline is behind on: partnerships whose stage or conversions moved on the cards but not "
                    "yet in the CRM, and what is already waiting for approval.",
     "inputSchema": {"type": "object", "additionalProperties": False, "properties": {}}},
    {"name": "rel_crm_prepare", "read": False, "handler": _t_crm_prepare,
     "description": "Prepare the CRM pipeline moves and conversion notes that are due, as one action for the owner's signed "
                    "approval. You never write to the CRM yourself; the sender does it after approval.",
     "inputSchema": {"type": "object", "additionalProperties": False, "properties": {}}},
]
