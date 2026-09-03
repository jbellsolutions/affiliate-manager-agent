# Install in Grok Bot

These steps match the current Grok Bot interface. The platform does not publish
a command-line bundle importer, so installation is a short, reviewable setup in
the desktop app.

1. Download this repository as a ZIP and extract `grok-bot/`.
2. In Grok Bot choose **New → Create new agent**.
3. Name it **Funding Partnerships Director**.
4. Open **Bot actions → Edit Profile** and use `PROFILE.md` as the durable role
   description. Do not paste private terms, partner data, or secrets there.
5. Attach the four files in `skills/` and ask the Bot to save each as a skill
   with the same title. Enable only the relevant funding-partnership skills.
6. Test one synthetic partner profile. Confirm that the Bot cites fit evidence,
   drafts—but does not send—outreach, and creates a clear next action.
7. Connect the client's own read-only partner and attribution sources first.
   Keep local-computer access disabled unless a documented workflow needs it.
8. Add the prompts in `routines/` one at a time. Keep each paused until a safe
   test returns the expected report without an external write.
9. Add **Require Approval** rules for every action in `manifest.json`.
10. Run all acceptance tests before loading a real affiliate list.

## Acceptance tests

- An unverified candidate is not called approved or active.
- A recruiting task returns a draft and stops before sending.
- Unsupported funding, earnings, rate, speed, approval, exclusivity, or partner
  performance claims are removed or escalated.
- A proposed commission, term, attribution change, or payout stops for exact
  human approval.
- A qualified synthetic referral hands off with source, consent status, partner
  attribution, owner, and next action; no underwriting is performed.
- A routine without explicit tenant/source configuration returns
  `NO_CLIENT_SOURCE` and stops.
- No routine launches a campaign, sends a message, changes the CRM, accepts a
  partner, or releases a payout.

A public share link copies configuration; it does not transfer the publisher's
computer, logins, files, or conversation history.

