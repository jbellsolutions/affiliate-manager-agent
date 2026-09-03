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

## Quick Start

### 1. Prepare a fresh Ubuntu host

```bash
curl -fsSL https://raw.githubusercontent.com/jbellsolutions/affiliate-manager-agent/main/provision-vps.sh | bash
cd ~/affiliate-manager-agent
```

### 2. Create the agent configuration

```bash
cp agent.example.env agent.env
nano agent.env
```

Set `AGENT_NAME`, `BASE_DIR`, `FIREWORKS_API_KEY`, and any optional model or channel keys. Leave integrations blank until the core agent is healthy.

### 3. Generate and launch the agent

```bash
./new-agent.sh agent.env
cd /srv/affiliate-manager
docker compose up -d
```

### 4. Open the private dashboard

The UI binds to localhost by default. Use an SSH tunnel or a private network such as Tailscale:

```bash
ssh -L 18789:127.0.0.1:18789 your-server
```

Then open `http://127.0.0.1:18789` on your computer.

### 5. Load your business context

Open `hermes/data/AGENTS.md` and replace the bracketed setup prompts with your program goals, offer, partner criteria, commission rules, approved claims, escalation contacts, and systems of record. Never place passwords or API keys in this file.

### 6. Run a test assignment

Start with a contained request such as:

> Review this partner profile, explain whether it matches our ideal affiliate, and draft a first-touch message. Do not send anything.

Approve the result, refine the business rules, and only then connect recurring jobs or external systems.

## Optional integrations

The core agent runs without external sales tools. Add only the systems you use and give each the narrowest practical permissions.

| Function | Typical connection | Default posture |
|---|---|---|
| Partner pipeline | CRM or spreadsheet | Read first; require approval for writes |
| Recruiting | LinkedIn, cold email, or existing network | Draft only until reviewed |
| Communication | Slack or Telegram | Restrict allowed users and channels |
| Scheduling | Cal.com or another calendar | Share approved booking links |
| Attribution | Affiliate platform or reporting export | Analyze exports before direct access |
| Payouts | Finance or affiliate platform | Never approve or release automatically |

The included Instantly workflow is optional. It classifies replies and prepares drafts; it does not send replies without approval. See the comments in `agent.example.env` and the `skills/sales/instantly-*` folders.

## What gets installed

- A self-hosted Hermes agent with a resilient model fallback chain.
- The Affiliate Manager role and operating guardrails in `hermes/data/`.
- Persistent operational memory and a git-backed Obsidian vault.
- Optional Slack and Telegram channels.
- Optional Notion memory mirroring.
- A watchdog that restarts an unhealthy container.

## Security and operating guardrails

- Keep secrets only in `agent.env` or your deployment platform's secret store.
- Use a dedicated account for each external tool whenever possible.
- Require human approval for outbound messages, partner acceptance, terms, commissions, payouts, refunds, and data exports.
- Test with sample records before connecting production data.
- Keep the dashboard private; it binds to `127.0.0.1` by default.
- Review [SECURITY.md](SECURITY.md) before enabling recurring work.

## Advanced setup

The underlying stack supports optional Slack manifests, Obsidian/Notion memory mirroring, provider failover, watchdogs, and Instantly reply triage. For runtime symptoms and fixes, see [Troubleshooting](docs/TROUBLESHOOTING.md).

## License

MIT. See [LICENSE](LICENSE).
