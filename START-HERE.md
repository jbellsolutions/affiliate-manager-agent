# Start Here: Affiliate Manager on Orgo

Affiliate Manager is a private, always-on operator for building and running an
affiliate or referral program. A setup agent handles the technical installation
from this repository. The owner steps in only for billing, private sign-in,
OAuth consent, or a secret entered through a protected field.

## Paste this one message into your setup agent

```text
Install Affiliate Manager from
https://github.com/jbellsolutions/affiliate-manager-agent

Read AGENTS.md, START-HERE.md, and docs/ORGO-SETUP.md. Before changing anything,
give me a short readiness briefing: what will be installed, what it may cost,
which accounts are required, which connections are optional, and every point
where I will need to approve or sign in. Inspect my Orgo account and reuse the
computer named affiliate-manager if it exists. Handle every technical step.
Keep credentials out of chat, screenshots, logs, and Git. Start with manual
approval for every external write. Finish only after orgo/verify.sh passes, a
synthetic affiliate workflow passes, and I receive one real reply through the
authorized dashboard or messaging channel.
```

## What you need ahead of time

Required:

- Access to an Orgo workspace and approval to use one 8 GB RAM / 4 vCPU
  computer. Orgo billing and capacity depend on the account's current plan.
- One model provider supported by Hermes. The setup agent will use Hermes'
  private setup flow and will not place the key in this repository.
- Five business answers: the offer, ideal affiliate, approved commission and
  terms, approved/prohibited claims, and the person who approves external work.

Optional:

- Telegram or Slack if you want to message the agent away from its private
  dashboard.
- CRM, affiliate platform, calendar, inbox, files, or Instantly credentials.
  These are connected only after the core agent answers correctly.

You do not need to know the terminal, Docker, Git, or configuration files.

## What the setup agent will do

1. Explain the plan, costs, account needs, security boundaries, and approval
   moments before making changes.
2. Inspect Orgo and reuse the intended computer, or request approval before
   creating a billable one.
3. Install the exact reviewed Hermes v0.21.0 release and the Affiliate Manager
   profile, skills, policies, private folders, and desktop launchers.
4. Help the owner complete model authentication through a private flow.
5. Prove a harmless local response.
6. Connect only the selected messaging and business tools, testing reads first.
7. Run repository checks and a synthetic partner workflow.
8. Deliver a plain-English completion card: what works, how to open it, what is
   still disconnected, and how to stop external writes immediately.

The installation normally completes in one guided session once the required
accounts are ready. Download and provider-authentication time varies.

## First-run interview

The setup agent must capture these answers without inventing them:

1. What business, offer, customer, price, and sales process is the program
   promoting?
2. What is the primary target: partner-sourced revenue, active affiliates,
   qualified leads, or another metric?
3. Who is an ideal affiliate, and who must be excluded?
4. What commission, cookie, qualification, refund, and payout terms are already
   approved?
5. Which claims are evidence-backed and allowed? Which claims are prohibited?
6. Which system is authoritative for partners, links, clicks, leads,
   conversions, revenue, attribution, and payout status?
7. Who approves outreach, affiliate acceptance, public content, term changes,
   attribution changes, exports, and payouts?
8. What is the escalation route for compliance, brand, privacy, or partner
   disputes?

Store the answers only in the private computer. Shared copies of this repository
must remain blank and reusable.

## First operating proof

Use a made-up partner and made-up performance numbers. Ask the agent to:

> Evaluate this synthetic partner against our approved profile, show the facts
> and assumptions separately, recommend the next action, and draft an outreach
> message. Do not send, publish, approve, or change any record.

Then confirm it refuses to change commission terms, attribution, or payout
status without the named human approval.

## Stop or resume external work

`./orgo/emergency-stop.sh "reason"` records an emergency stop and disables the
connected business-app MCP. Research and drafting remain available. Only the
account holder should run `./orgo/resume-external-writes.sh` after reviewing the
reason and reconnecting any intentionally disabled tool.

The older Docker/VPS deployment remains available for technical teams, but Orgo
is the recommended beginner path.
