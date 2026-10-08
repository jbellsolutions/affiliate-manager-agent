"""The partner pipeline, in Obsidian: where every revenue partnership is, and where it came from.

    python3 -m relcore pipeline        writes Reports/Partner pipeline <date>.md

Stages are the same ladder the CRM follows (crm.PIPELINE): conversation stages from the cards, conversion stages
from the partner platform only. Origin is how the partnership's first contact came to us: introduced by someone on
the graph, or the source on their record (a website form, research, an event, the existing CRM list). The charts
are Mermaid, which Obsidian draws natively.
"""
from __future__ import annotations

import json

from . import clock, crm

NEW = "Not contacted yet"



def _slot(profile, name):
    v = profile["slots"].get(name)
    return v[0]["value"] if v else None


def _sources(store, person: str) -> list[str]:
    hubs = [e["other"] for e in store.edges(person, typ="member_of_hub", direction="out") if e["other"].startswith("hub:Sources/")]
    return sorted(h.split("/", 1)[1] for h in hubs)


def origin(store, ps: str) -> str:
    people = [e["other"] for e in store.edges(ps, typ="contact_for", direction="in")]
    for person in people:
        intro = store.edges(person, typ="introduced_by", direction="out")
        if intro:
            return f"Introduced by {store.label(intro[0]['other'])}"
    for person in people:
        src = [s for s in _sources(store, person) if s.lower() != "owner"]
        if src:
            return {"GHL import": "Existing CRM list"}.get(src[0], src[0])
    return "Unknown"


def build(store) -> dict:
    rows = []
    for ps in store.all_ids("partnership"):
        p = store.profile(ps)
        stage = crm.reached(store, ps)
        rows.append({"partnership": ps, "label": store.label(ps), "link": store.vault.wikilink(ps).replace("|", "\\|"),
                     "partner": store.label(ps).split(" x ", 1)[-1].rsplit(" - ", 1)[0],
                     "type_id": store.entity(ps)["fields"].get("type_id", ""), "stage": crm.LABEL.get(stage, NEW) if stage else NEW,
                     "origin": origin(store, ps), "conversions": int(_slot(p, "conversions") or 0),
                     "crm_stage": crm.LABEL.get(_slot(p, "crm_stage") or "", "") or None})
    order = [NEW, *[crm.LABEL[s] for s in crm.PIPELINE]]
    by_stage = {s: sum(1 for r in rows if r["stage"] == s) for s in order}
    origins = sorted({r["origin"] for r in rows})
    by_origin = {o: {"partnerships": sum(1 for r in rows if r["origin"] == o),
                     "contacted": sum(1 for r in rows if r["origin"] == o and r["stage"] != NEW),
                     "engaged": sum(1 for r in rows if r["origin"] == o and order.index(r["stage"]) >= order.index("Engaged")),
                     "conversions": sum(r["conversions"] for r in rows if r["origin"] == o)} for o in origins}
    return {"at": clock.day(clock.now()), "rows": rows, "by_stage": by_stage, "by_origin": by_origin,
            "crm_behind": sum(1 for r in rows if r["stage"] != NEW and r["stage"] != (r["crm_stage"] or NEW))}


def _q(text: str) -> str:
    return text.replace('"', "'")


def markdown(card: dict) -> str:
    lines = ["---", "type: report", "tags:", "  - trp/pipeline", "---", f"# Partner pipeline {card['at']}", "",
             "Where every revenue partnership is, and where it came from. Stages come from the cards, conversions from "
             "the partner platform, never from message volume.", "", "## Where they are", "", "| Stage | Partnerships | |", "|---|---|---|",
             *[f"| {k} | {v} | {'█' * (3 * v)} |" for k, v in card["by_stage"].items()], "",
             "## Where they came from", "", "```mermaid", "sankey-beta", ""]
    flows = {}
    for r in card["rows"]:
        flows[(r["origin"], r["stage"])] = flows.get((r["origin"], r["stage"]), 0) + 1
    lines += [f'"{_q(o)}","{_q(s)}",{n}' for (o, s), n in sorted(flows.items())]
    lines += ["```", "", "| Came from | Partnerships | Contacted | Engaged or further | Conversions on record |", "|---|---|---|---|---|"]
    for o, v in sorted(card["by_origin"].items(), key=lambda kv: -kv[1]["partnerships"]):
        lines.append(f"| {o} | {v['partnerships']} | {v['contacted']} | {v['engaged']} | {v['conversions']} |")
    lines += ["", "## Every partnership", "", "| Partnership | Type | Stage | CRM stage | Came from | Conversions |", "|---|---|---|---|---|---|"]
    order = list(card["by_stage"])
    for r in sorted(card["rows"], key=lambda r: (-order.index(r["stage"]), r["label"])):
        lines.append(f"| {r['link']} | {r['type_id']} | {r['stage']} | {r['crm_stage'] or 'not synced'} | {r['origin']} | {r['conversions']} |")
    lines += ["", f"CRM records behind the cards: {card['crm_behind']}."]
    return "\n".join(lines) + "\n"


def write(store) -> dict:
    card = build(store)
    rel = f"Reports/Partner pipeline {card['at']}.md"
    store.vault._write(rel, markdown(card))
    card["note"] = rel
    return card


def main(argv=None) -> int:
    from . import config
    from .store import Store
    card = write(Store(config.resolve()))
    print(json.dumps({k: card[k] for k in ("note", "by_stage", "by_origin", "crm_behind")}, indent=1))
    return 0


def _t_pipeline(srv):
    card = write(srv.store)
    return {k: card[k] for k in ("note", "by_stage", "by_origin", "crm_behind")}


MCP_TOOLS = [
    {"name": "rel_pipeline", "read": True, "handler": _t_pipeline,
     "description": "The partner pipeline: how many partnerships sit at each stage, where they came from (introductions, "
                    "forms, research, events, the CRM list) and how far each origin gets. Writes a Reports/ note with charts.",
     "inputSchema": {"type": "object", "additionalProperties": False, "properties": {}}},
]
