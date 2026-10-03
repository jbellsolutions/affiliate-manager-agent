# Relationship cards and the context graph

Every person, partner and partnership in the affiliate program gets a living relationship card in an Obsidian vault
(`~/AffiliateVault` on the Orgo computer), and the agent reads the context graph before it writes a word. Open the
vault in Obsidian to see what the agent knows about each relationship, where each fact came from, what is still open
and what happens next. The graph view clusters the program by partner type, niche, channel and stage.

The layer is `relcore/`, a standard-library Python package built and tested in True Revenue Partner and copied here
unchanged. This page covers how it runs on this install.

## What the owner sees

| Folder | One note per | What it shows |
|---|---|---|
| `People/` | person | how to reach them, time zone and its basis, preferred channel, consent per channel, do-not flags, open loops, facts with sources, the last conversation quoted, the timeline |
| `Partners/` | partner organization or solo affiliate | who they reach and how many, niches, promo channels, regions, goals, research with URLs |
| `Partnerships/` | partnership (business x partner x partner type) | the partner type, stage, record fields (tier, link, code, conversions), why a partner is left out of waves, the partner plan, terms (owner only) |
| `Employees/`, `Hubs/`, `Calls/`, `Plans/`, `Reviews/` | portfolio, tag, call, plan, prepared message | the program at a glance, call commitments, the plan we promised, every prepared message |

Partner types are the 41 affiliate types in `data/affiliate-partner-types.json`: content and review sites, deal and
coupon sites, paid traffic, email lists, sub-networks, commerce tech, communities, B2B affiliates and customers.

## The rules the code enforces

- **Every fact has a source** (owner, record, call, reply, plan, research) and a recorder. Tier, joined date,
  lifecycle, segment, links, codes, conversions and consent come only from an import or the owner.
- **Never stored:** health, religion, politics, sexual orientation, minors, government and account numbers,
  payment cards and passwords, on every write path. A sentence that carries one is dropped.
- **Context before every draft.** `rel_context` returns a bounded brief (DO NOT, WHO, KNOWN, OPEN LOOPS, LAST
  CONVERSATION, GRAPH, NEXT QUESTION) and a digest; a draft written from stale context is refused.
- **Copy rules on every draft:** length, one question, no links on a first touch, no earnings claims, no re-asking
  what is known, never the same unanswered question twice.
- **Partner text is data,** shown quoted, never treated as instructions.

## Drafts only on Orgo

An Orgo computer has no systemd and the installing user is an administrator, so a separate approvals service and
sender (the way True Revenue Partner sends email and SMS after a signed approval) cannot be kept out of the agent's
reach here. relcore therefore runs drafts only:

1. `rel_wave_prepare` or `rel_draft_submit` prepares messages; each lands in
   `~/.hermes/affiliate-manager/private-business/outbox/` and in `Reviews/` in the vault.
2. You send it yourself. Tell the agent it went out and it records it with `rel_sent_record`: the card shows the
   message and the person counts as contacted for good. A first touch waiting in the outbox already counts, so no
   later wave picks that person again; if you decide not to send it, have the agent withdraw it
   (`rel_action_withdraw`).
3. Paste the partner's reply to the agent. `rel_reply_record` reads it through the keyword floor (opt-out, HELP,
   wrong number, identity question, complaint, then the positive intents), applies opt-outs and wrong numbers at
   once, opens loops (a confirmed time, a calendar hold), records engagement and tells the agent which reply move
   is allowed.

relcore has no send, approve or release tool, and the server refuses to register one. In this mode the sends and
replies on the cards are what you told the agent, not what a provider reported, so reply and engagement rates rest
on that record; conversions still come only from your affiliate platform or CRM import.

## Set up and import

`./orgo/setup.sh` creates the vault and registers the relcore MCP server with Hermes (step 5). Then import your
partners from a CRM export:

```bash
./orgo/relationship.sh import plan csv <folder> --client "<your business>"
```

`plan` shows what would change; run it again with `apply` to write the cards. The folder layout and columns are in
`examples/relationship/` (a fictional program). DNC and active-producer lists become restrictions and exclusions.
Other commands: `card <email or phone>`, `context <email or phone>`, `scorecard`, and `purge <email or phone>`
(forget a person; add `--yes` to remove).

## Proof

- `tests/test_relationship_cards.py` (every `scripts/verify.sh` run): the sample imports into cards, restrictions
  and exclusions show, the MCP server lists no send tool, `rel_context` returns the brief, a wave lands in the
  outbox, and every tool maps to a tier 0 or 1 action in `policies/permissions.json`.
- `tests/smoke_relationship.sh` (CI, the exact reviewed image): a non-root desktop user runs the setup block,
  `hermes mcp test relcore` connects and lists the tools, and the sample becomes cards.

## Existing Composio connection

`./orgo/connect.sh` gives the agent the full Composio toolset, which includes send tools for any account connected
there. relcore cannot close that path. Until it is narrowed with `mcp_servers.composio.tools.include` to read tools
only, connect only accounts the agent may read, or keep relying on `approvals.mode=manual` for every call.

## Live sending later

To send email and SMS after a signed approval, as True Revenue Partner does, the approvals service and the sender need
a machine the agent's user cannot administer: a small separate host that shares only the spool folder, or separate
containers on the VPS once the agent container no longer mounts the Docker socket. That is a deliberate owner
decision; until then everything stays drafts only.
