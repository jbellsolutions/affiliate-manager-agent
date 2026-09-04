# Affiliate Manager Agent

![Affiliate Manager Agent coordinating a partner network](docs/assets/affiliate-manager-hero.jpg)

Your always-on AI operator for recruiting, activating, supporting, and growing revenue-producing partner relationships.

This repository installs a guarded [Hermes](https://github.com/NousResearch/hermes-agent) agent with an Affiliate Manager operating brief, persistent memory, optional Slack or Telegram access, and an optional cold-email workflow. The agent prepares work and keeps the program moving; a human remains in control of outreach, terms, payouts, and account access.

## The business outcome

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

- An Orgo workspace with capacity for one 8 GB RAM / 4 vCPU computer.
- One model provider supported by Hermes.
- Your offer, ideal affiliate, approved terms, approved/prohibited claims, and
  human approver.
- Optional Slack, Telegram, CRM, affiliate-platform, calendar, inbox, file, or
  Instantly access.

No CRM or affiliate-platform login is needed to install and test the core agent.
Connections are added only after it produces a correct local response.

## What happens during setup

1. The setup agent presents a plain-English readiness and cost briefing.
2. It inspects Orgo, reuses `affiliate-manager` when appropriate, or asks before
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

- An Orgo-first Hermes v0.21.0 agent pinned to an exact release, commit, Docker
  digest, and installer checksum.
- The Affiliate Manager role and operating guardrails in `hermes/data/`.
- Current checkpoints, memory, verification-on-stop, secret and PII redaction,
  manual approvals, cron-deny, loop-stop, and reviewed-skill settings.
- Persistent operational memory and a git-backed Obsidian vault.
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
Orgo contract. The dashboard remains bound to localhost. For runtime symptoms,
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
