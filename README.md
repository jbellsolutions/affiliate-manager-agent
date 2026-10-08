# Affiliate Manager Agent

> **[Orgo](https://orgo.ai?r=aiguy) partner offer:** Get 25% off your first three months on a monthly plan or your first year on a yearly plan. Add-ons are not discounted.

![Affiliate Manager Agent coordinating a partner network](docs/assets/affiliate-manager-hero.jpg)

Your always-on AI operator for recruiting, activating, supporting, and growing revenue-producing partner relationships, with a living relationship card for every affiliate, partner and partnership.

This repository installs a guarded [Hermes](https://github.com/NousResearch/hermes-agent) agent with an Affiliate Manager operating brief, persistent memory, optional Slack or Telegram access, and an optional cold-email workflow. The agent prepares work and keeps the program moving; a human remains in control of outreach, terms, payouts, and account access.

## Your partners remember every conversation. Now your program does too.

![A relationship card in Obsidian: Dana Ortiz, practice manager at a partner clinic](docs/assets/relationship/hero-obsidian.png)

*A real card from the fictional sample program, open in Obsidian. Every line on it has a source.*

Most partner programs do not die from a bad offer. They die from forgetting.

The practice manager who told you "text is easier for me than email" gets an email. The surgeon who offered Wednesday gets a generic follow-up on Friday. The referral pad you promised on the call never ships. Your best producer gets the same "want to partner?" note as a stranger. Nobody remembers who introduced whom.

None of that is a copywriting problem. It is a memory problem. More messages make it worse.

**The Relationship Layer fixes the memory.** Every person, every partner and every revenue partnership gets a living card. The cards link into one context graph. And the agent has to read that graph before it is allowed to write a single word.

## Why "AI outreach" keeps burning good partners

- **Volume tools send more. They do not remember more.** A faster way to repeat yourself is still repeating yourself.
- **A CRM stores fields, not relationships.** It knows a tier and a link. It does not know what they asked last, what you promised, or that the gym owner and the chiropractor are the same introduction chain.
- **An agent with no memory re-asks, over-asks and asks too early.** That is how a partner who sent you clients for two years ends up unsubscribing.

The fix is not a better template. It is a system where context comes first, every fact carries its source, and production is measured from your system of record, never from message volume.

## The Relationship Layer

Three kinds of cards, one graph, one rule.

| Card | What it holds |
|---|---|
| **Person** | How to reach them, consent per channel, time zone and how we know it, preferred channel, roles, facts with sources, open loops, calls, the last conversation (quoted) and a timeline |
| **Partner** | The organization or solo partner: record fields from your system of record, audience and size, niches, promo channels, regions, research with sourced links |
| **Partnership** | The revenue partnership itself: who is involved and their roles, the partner type, the owning employee and the named sender, stage, program segment, holdout, next step, terms (owner only), open loops and the partner plan |

**The rule:** before any draft, the agent pulls `rel_context`, a bounded brief with do-not flags first, key facts with sources, open loops, the last five interactions quoted, ranked neighbors, the partner-type playbook and the next question to ask. The brief carries a digest. A draft written from stale context, or from none, is refused.

![A partnership card: who is involved, the partner type and why they say yes, the program stage and the partner plan](docs/assets/relationship/partnership-card.png)

*A partnership card. Partner type, the named sender, the owning employee and the plan, all on one page.*

## Everything you get

- [x] **A living card for every person, partner and partnership**, as plain Markdown in an Obsidian vault you own
- [x] **A context graph** linking people to partners, partners to partnerships, partnerships to partner types, owners, offers, campaigns, niches, channels, regions and stages
- [x] **Warm introduction paths** found on the graph, not guessed
- [x] **Context before every draft**, enforced by a digest check
- [x] **Facts with sources**: owner, record, call, reply, plan or research, plus who recorded it
- [x] **Edit in Obsidian**: add or delete a fact line on a card and relcore keeps the change
- [x] **Copy rules enforced in code**: one ask per message, no links or call requests on a first touch, email 50 to 100 words with a short lowercase subject, SMS at most 2 segments, no hype, no earnings claims, no mention of AI
- [x] **Waves with a holdout**: 15% of each segment is held back as a control once the segment is big enough to hold one out, so you can see what the outreach actually changed
- [x] **A review note for every wave**, anomalies first, messages grouped by template and hook
- [x] **A clean outbox**: you send each prepared message yourself, then the agent records it on the cards
- [x] **Reply triage with an intent floor**: opt-outs, wrong numbers and identity questions are handled first, before any model reads the text
- [x] **Calls turned into commitments**: who promised what, by when, as open loops on the partnership
- [x] **A partner plan** the partner actually receives: the offers that fit their people, the moments they need it, a message they can copy, and what you will send them
- [x] **A scorecard** built from production on record, with lift measured against the holdout
- [x] **Employee portfolio cards**: each AI employee sees its own partnerships, loops due and next asks
- [x] **No paid enrichment**: the agent researches partners itself with its own browser and computer

## How the whole workflow works

```text
Import  ->  Cards + graph  ->  Context brief  ->  Wave + holdout  ->  Owner review
                                                                        |
Scorecard  <-  Partner plan  <-  Calls  <-  Replies triaged  <-  Approved send
```

### 1. Import what you already have

- [x] CSV exports, a read-only CRM pull or a platform export
- [x] Phone numbers normalized, duplicates merged, one person with two numbers stays one person
- [x] Active producers and do-not-contact lists become exclusions and restrictions on the cards
- [x] Every imported fact is tagged with where it came from

### 2. Cards and the graph appear

- [x] A card for every person, partner and partnership, linked together
- [x] Each partnership is typed against the partner map and linked to its playbook
- [x] Hubs for tier, niche, promo channel, source, offer, campaign, region and stage, so Obsidian's graph view clusters the whole program

![Obsidian graph view of the sample program: partnerships, people, partners, employees and hubs](docs/assets/relationship/context-graph.png)

*The sample program in Obsidian's graph view. Orange: partnerships. Blue: people. Teal: partners. Purple: AI employees. Red: calls. Gray: hubs.*

### 3. The agent reads before it writes

- [x] `rel_context` returns the brief: do-not flags, facts, open loops, the last five interactions, neighbors
- [x] The next question is chosen so nobody is asked the same thing twice
- [x] The draft must quote the brief's digest or it is refused

![A person card: profile, how to reach them, consent per channel, preferred channel, open loops and facts](docs/assets/relationship/person-card.png)

### 4. A wave is prepared, with its holdout

- [x] Recipients picked by segment, skipping the excluded, the reserved, the held out and anyone already contacted
- [x] Each message linted against the copy rules, each recipient reserved so two waves never collide
- [x] A review note lands in `Reviews/`: anomalies first, the selection rule, what was skipped and why

![A wave review note: anomalies, the selection rule, how many were picked and why two were skipped](docs/assets/relationship/wave-review.png)

### 5. A human approves, every time

- [x] On Orgo there is no sender: prepared messages wait in the outbox for you
- [x] You send each one yourself, then the agent records it with `rel_sent_record`
- [x] Until it is recorded or withdrawn, that person still counts as contacted, so nobody gets two first touches

![A signed approval mirrored to Obsidian, from the True Revenue Partner droplet path](docs/assets/relationship/signed-approval.png)

*Shown from the True Revenue Partner droplet path, where a separate service signs approvals and sends. On Orgo the same review happens in the outbox, and you are the sender.*

### 6. Every message is checked again at the moment it goes out

- [x] On the True Revenue Partner droplet a separate sender verifies the signature and re-checks the window, caps, suppression, first touch and staleness for every message
- [x] On Orgo you are the sender, and the cards still hold the line: exclusions, do-not-contact, consent and one first touch per person are applied when the wave is prepared

### 7. Replies are triaged, and opt-outs win

- [x] An ordered keyword floor reads each reply first: opt-out, wrong number, identity question, complaint
- [x] A model can refine the intent but can never downgrade an opt-out, an identity question or a complaint
- [x] Partner text is stored as quoted data, never as instructions
- [x] On Orgo you paste what the partner wrote and `rel_reply_record` runs the exact same path
- [x] Answers to a partner's own latest message are prepared for approval, and the agent may not re-ask a question they just answered

![Recent conversation on a person card: what we wrote and what they wrote, quoted](docs/assets/relationship/person-conversation.png)

### 8. Calls become commitments

- [x] A transcript dropped in the call inbox becomes a call note linked to the people on it
- [x] Sensitive details are dropped before the note is written
- [x] What each side promised becomes an open loop with a due date, as a checkbox you can tick in Obsidian

![A call note: commitments as checkboxes, what was learned, and the redacted transcript](docs/assets/relationship/call-note.png)

![Open loops on a partnership card: what we owe and what they owe, with due dates](docs/assets/relationship/partnership-loops.png)

### 9. The partner gets a plan they can use

- [x] Their link, the offers that fit their people, the moments their people need it
- [x] A message they can copy and paste, and the assets you will send them
- [x] An internal half: what we promised and the one measure we watch

![A partner plan note: what the partner gets, and the internal promises and measure](docs/assets/relationship/partner-plan.png)

### 10. The scorecard judges the program by production

- [x] Reachable, consented partnerships as the denominator
- [x] Replies, positive replies, our median time to reply, the funnel from engaged to repeat
- [x] Conversions from your system of record, calls held, plans sent, open grievances
- [x] Each wave against its holdout, with a caution when the numbers are too small to read

![The relationship scorecard: reachable partnerships, replies, funnel, conversions and each wave](docs/assets/relationship/scorecard.png)

## Where it runs

relcore, the engine behind the cards, ships in two products: **True Revenue Partner** (the full partnership program builder) and **[Affiliate Manager Agent](https://github.com/jbellsolutions/affiliate-manager-agent)** (the affiliate operator on Orgo).

| | True Revenue Partner on a droplet | Affiliate Manager on Orgo | True Revenue Partner as a Claude Code plugin |
|---|---|---|---|
| Cards, graph, context briefs | yes | yes | yes |
| Waves, holdouts, review notes, lint | yes | yes | yes |
| Email and SMS | sent after a signed owner approval, by a separate sender | drafts: you send, the agent records | drafts: you send, the agent records |
| Replies | read by the sender's inbox | pasted by you, triaged the same way | pasted by you, triaged the same way |
| LinkedIn and DMs | drafts only | drafts only | drafts only |
| Calls, plans, scorecard | yes | yes | yes |

## Partner types: the whole map

Every partnership is typed, and every type carries a playbook: what the partner is, why they say yes, the opener and the objections. The True Revenue Partnerships map has **11 families, 67 subcategories and 339 partner types**.

| Family | | Subcategories | Types |
|---|---|---|---|
| **F1** Affiliates | two axes, 41 partner types, and a 60-day cookie norm | 9 | 41 |
| **F2** Influencers & Creators | buying a person's voice, not an ad slot | 6 | 24 |
| **F3** Sponsorships | rate-card inventory in someone else's property | 5 | 35 |
| **F4** Co-Promotion | pooled audiences, shared list or shared revenue | 6 | 38 |
| **F5** Stages & Media | a separate family, defined by who owns the platform | 7 | 48 |
| **F6** Referral & Power Partners | named introductions and endorsed JVs | 7 | 26 |
| **F7** Access Partners | paying for the room, not the sale | 6 | 31 |
| **F8** Channel Partners | they sell, deliver, bill or embed your offer | 5 | 25 |
| **F9** Strategic Alliances & Licensing | IP, equity and co-owned products | 7 | 27 |
| **F10** Cause & Nonprofit Partners | giving tied to sales or traffic | 4 | 15 |
| **F11** House Partners | your own customers, leads, staff and alumni | 5 | 29 |

**This repository ships Family 1, Affiliates**, in `data/affiliate-partner-types.json`: 9 subcategories and 41 partner types (Content & editorial publishers; Deal & incentive publishers; Performance & paid-traffic affiliates; Email & list owners; Aggregators & sub-networks; Technology & commerce-enablement partners; Community & micro-creator affiliates; B2B & professional affiliates; Customer & alumni affiliates). The other ten families are part of True Revenue Partner. Partners that fit no installed type fall back to a small generic map.

## What it will never do

- [x] Send anything without a human: a signed approval on the droplet, your own hand everywhere else
- [x] Contact a holdout, an excluded producer, anyone on do-not-contact, or anyone without consent on file for that channel
- [x] Send a second first touch to the same person or the same address
- [x] Store health details, card numbers, ID numbers or the other never-store categories, on any path
- [x] Treat a partner's words as instructions
- [x] Set or change terms, payouts or commissions. Terms are written by the owner only
- [x] Buy data. There is no paid enrichment, by rule
- [x] Keep going after the kill switch. One command stops every external write

## Proof, not promises

Every rule above is a test. These numbers prove the rules hold. They are not a forecast of your results.

- [x] relcore is built and tested in True Revenue Partner: 152 unit tests, a smoke test in the pinned Hermes image, and the simulation below
- [x] Here, `tests/test_relationship_cards.py` and `tests/smoke_relationship.sh` prove the Orgo install: the sample imports into cards, the MCP server is drafts-only, and no tool can approve, send or sign
- [x] **A simulation with hidden-truth personas**: 40 synthetic partners over 9 simulated days, two seeds, through prepare, approval, the sender's checks, the inbox and replies, with an unknown outcome and a rate-limit error injected. Both seeds pass all 18 checks, including:

  - [x] the provider never got the same message twice
  - [x] an unknown outcome halted the sender until the owner resolved it
  - [x] a rate-limit error before acceptance was retried and sent, not dropped
  - [x] a reply that pushed after a "not now" or a "no" was refused, then revised
  - [x] one first touch per person, and one per address
  - [x] nothing sent after an opt-out or to a wrong number
  - [x] every SMS inside 09:00 to 20:00 in the recipient's own time zone
  - [x] caps held across every channel (1 a day, 2 a week)
  - [x] one answer per partner message
  - [x] the holdout was never contacted
  - [x] active producers and people without consent were never contacted
  - [x] a health detail was told on a reply and never stored
  - [x] the audience sizes partners mentioned landed on their partner cards
  - [x] the scorecard's denominator equals the reachable, consented partnerships

See it yourself, with fictional data only:

```bash
./orgo/relationship.sh init
```

```bash
./orgo/relationship.sh import apply csv examples/relationship --client "Northwind Outdoor Gear"
```

Run these on the Orgo computer after setup, then open `~/AffiliateVault` in Obsidian to see a card for every sample affiliate. The screenshots on this page come from the True Revenue Partner sample program.

## The value equation

- **The outcome you want:** a partner program that grows from the relationships you already have, where every partner feels remembered.
- **Why you can believe it:** nothing here asks for faith. Every card shows its sources, every rule is a test, and every wave is measured against people you did not contact.
- **Less waiting:** import the list you already have and the cards are there. No rebuild, no migration project.
- **Less effort:** the agent researches, drafts, records and keeps the loops. You read the review and decide.

## Questions

**Do I need Obsidian?** The cards are plain Markdown files. Obsidian, a free app, gives you the links and the graph view. Any editor can read them.

**Can it send without me?** No. On Orgo it never sends. You send, and it records.

**What about LinkedIn and DMs?** Drafts only, everywhere.

**Does it buy contact data?** No. It researches partners itself with its own browser and computer, and every researched fact stays low confidence until the partner confirms it.

**What if I edit a card?** Add or delete fact lines and relcore keeps the change. Protected fields like consent, production and terms come only from the system of record or the owner, so a file edit can never restore a suppression or invent a sale.

**Is the sample data real?** No. Harborline Physical Therapy and everyone in it are fictional, with example.com addresses and 555 numbers.

**Will this get me more referrals?** No tool can promise that, and this one does not. It makes sure every partner is treated like you remember them, and it tells you honestly, against a holdout, what changed.

## What the Affiliate Manager does

The Relationship Layer is the memory. The agent around it is the operator.

Most affiliate programs do not fail because the offer is bad. They stall because recruiting is inconsistent, onboarding is vague, campaigns arrive late, follow-up stops, and nobody owns the partner pipeline. This agent gives the program an operator.

It can help you:

- Define the ideal affiliate profile and build a recruiting queue.
- Research and qualify potential partners.
- Prepare personalized outreach and follow-up drafts for approval.
- Onboard approved affiliates with the right links, assets, and campaign brief.
- Maintain a partner CRM, next actions, and reactivation list.
- Build launch kits, swipe copy, content prompts, and promotion calendars.
- Monitor program health and prepare weekly performance reports.
- Surface stalled partners, attribution questions, and payout exceptions.

Relationship cards on Orgo, step by step: [docs/RELATIONSHIP-CARDS.md](docs/RELATIONSHIP-CARDS.md).

## The operating cycle

```text
Program strategy → Partner sourcing → Human-approved outreach → Onboarding
        ↑                                                    ↓
Reporting and optimization ← Attribution review ← Activation and support
```

The default role files make three rules explicit: the agent drafts before it sends, never changes commercial terms or payouts without approval, and never commits credentials or prospect data to git.

## Start in one message

Give this repository link to a capable setup agent:

```text
https://github.com/jbellsolutions/affiliate-manager-agent
```

Then say:

```text
Install this Affiliate Manager for me. Read AGENTS.md and START-HERE.md first.
Tell me what I need, what may cost money, what you will change, and every point
where I must approve or sign in. Handle all technical work, keep credentials in
private prompts or the secret vault, reuse my existing Orgo computer if it is
the intended one, and finish only after the repository checks, a synthetic
affiliate workflow, and one real channel reply all pass.
```

That is the recommended beginner path. The setup agent performs the computer
work and pauses only for billing, sign-in, OAuth consent, or private credential
entry. [START-HERE.md](START-HERE.md) contains the complete handoff.

## What to have ready

- An [Orgo](https://orgo.ai?r=aiguy) workspace with capacity for one 8 GB RAM / 4 vCPU computer.
- One model provider supported by Hermes.
- Your offer, ideal affiliate, approved terms, approved/prohibited claims, and
  human approver.
- Optional Slack, Telegram, CRM, affiliate-platform, calendar, inbox, file, or
  Instantly access.

No CRM or affiliate-platform login is needed to install and test the core agent.
Connections are added only after it produces a correct local response.

## What happens during setup

1. The setup agent presents a plain-English readiness and cost briefing.
2. It inspects [Orgo](https://orgo.ai?r=aiguy), reuses `affiliate-manager` when appropriate, or asks before
   creating a billable computer.
3. It installs the exact reviewed Hermes v0.21.0 release and this repository's
   identity, skills, policy, private folders, and launchers.
4. The owner completes model authentication privately.
5. The agent runs a harmless local test, then connects only authorized tools.
6. It runs the repository verification and a synthetic partner workflow.
7. It delivers a completion card showing what is live, tested, and intentionally
   left disconnected.

The installation normally completes in one guided session once the required
accounts are available. Provider downloads and authentication time vary.

## First assignment

Use synthetic data first:

> Evaluate this made-up partner against our approved affiliate profile. Separate
> facts from assumptions, recommend the next action, and draft a first-touch
> message. Do not send, publish, accept, or change any record.

Only then add real systems or recurring work.

## Optional integrations

The core agent runs without external sales tools. Add only the systems you use and give each the narrowest practical permissions.

| Function | Typical connection | Default posture |
|---|---|---|
| Partner pipeline | CRM or spreadsheet | Read first; require approval for writes |
| Recruiting | LinkedIn, cold email, or existing network | Draft only until reviewed |
| Communication | Slack or Telegram | Restrict allowed users and channels; Slack requires an owner Member-ID allowlist |
| Scheduling | Cal.com or another calendar | Share approved booking links |
| Attribution | Affiliate platform or reporting export | Analyze exports before direct access |
| Payouts | Finance or affiliate platform | Never approve or release automatically |

The included Instantly workflow is optional. It classifies replies and prepares
drafts; it contains no automatic-send path. See `agent.example.env` and the
`skills/sales/instantly-*` folders.

## What gets installed

- An [Orgo](https://orgo.ai?r=aiguy)-first Hermes v0.21.0 agent pinned to an exact release, commit, Docker
  digest, and installer checksum.
- The Affiliate Manager role and operating guardrails in `hermes/data/`.
- Current checkpoints, memory, verification-on-stop, secret and PII redaction,
  manual approvals, cron-deny, loop-stop, and reviewed-skill settings.
- Persistent operational memory and a git-backed Obsidian vault.
- Relationship cards and a context graph for every partner (`relcore`, drafts only on Orgo).
- Optional Slack and Telegram channels.
- A private connection menu for supported CRM, affiliate, calendar, inbox, file,
  and Instantly workflows.
- An emergency external-work stop and owner-confirmed recovery path.
- Optional Notion memory mirroring.
- A watchdog that restarts an unhealthy container.

## Security and operating guardrails

- Keep secrets only in `agent.env` or your deployment platform's secret store.
- Use a dedicated account for each external tool whenever possible.
- Require human approval for outbound messages, partner acceptance, terms, commissions, payouts, refunds, and data exports.
- Test with sample records before connecting production data.
- Keep the dashboard private; it binds to `127.0.0.1` by default.
- Review [SECURITY.md](SECURITY.md) before enabling recurring work.

The emergency stop is `./orgo/emergency-stop.sh "reason"`. It records the stop
and disables the connected business-app MCP while leaving research and drafting
available.

## Advanced Docker/VPS setup

Technical teams may still use the existing Docker/VPS path:

```bash
curl -fsSL https://raw.githubusercontent.com/jbellsolutions/affiliate-manager-agent/main/provision-vps.sh | bash
cd ~/affiliate-manager-agent
./setup.sh
```

The Docker deployment now uses the same reviewed Hermes v0.21.0 image as the
[Orgo](https://orgo.ai?r=aiguy) contract. The dashboard remains bound to localhost. For runtime symptoms,
see [Troubleshooting](docs/TROUBLESHOOTING.md).

## Updates and verification

`./scripts/verify.sh` checks the install contract, scripts, Python, policies,
runtime pins, secret-free seed, and a fresh deployment layout. Continuous
verification runs on every push and pull request. See
[Runtime and update policy](docs/UPDATES.md) for the reviewed baseline and safe
release process.

## Funding Partnerships Director for Grok Bot

The sanitized, funding-specific Grok Bot edition is in
[`grok-bot/`](grok-bot/). It turns the general Affiliate Manager into a Funding
Partnerships Director with clear ownership of partner segmentation, recruiting,
onboarding, activation, campaign support, attribution review, reporting, and
reactivation. Follow [`grok-bot/INSTALL.md`](grok-bot/INSTALL.md) to create a
client-isolated copy.

## License

MIT. See [LICENSE](LICENSE).
