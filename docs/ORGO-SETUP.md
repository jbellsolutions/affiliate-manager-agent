# Beginner setup on Orgo

This is the recommended installation path. The person installing it gives the
GitHub link to a capable setup agent. The setup agent reads the repository,
explains the prerequisites, operates Orgo, installs the software, and proves the
result. The account holder does not need to use a terminal.

## Before anything changes

The setup agent must show a short readiness card containing:

| Item | Why it is needed | Owner action |
|---|---|---|
| Orgo computer | Isolated, always-on home for the agent | Approve creation or billing only if a suitable computer does not exist |
| Model provider | Powers Hermes responses | Sign in or enter a key through a private flow |
| Private dashboard or channel | Where the owner talks to the agent | Choose dashboard, Telegram, or Slack |
| Business rules | Prevents invented offers, terms, claims, and approvals | Answer the first-run interview |
| Optional business tools | CRM, affiliate platform, calendar, inbox, files, or Instantly | Authorize only the tools wanted now |

The setup agent must state that Orgo and model-provider charges depend on the
owner's current accounts. It must inspect existing resources before requesting
permission to create anything billable.

## Installation contract

1. Read `AGENTS.md`, `START-HERE.md`, `orgo/deployment.json`,
   `policies/permissions.json`, and `SECURITY.md`.
2. Run `./orgo/verify.sh --static` on the cloned repository.
3. Inspect the Orgo workspace. Reuse the computer named `affiliate-manager` when
   it is the intended machine. Otherwise ask before creating one.
4. If creation is approved, use `system/hermes-agent@1.0.0` with 8 GB RAM,
   4 vCPU, 40 GB disk, and 1440 x 900 resolution. Current Orgo guidance lists
   8 GB and 4 cores as the minimum for Hermes.
5. Clone this repository on the computer and run `./orgo/setup.sh`.
6. Use `hermes setup` or `hermes setup --portal` for private model
   authentication. Never relay the key through ordinary chat.
7. Run one harmless local prompt before connecting external systems.
8. Use `./orgo/connect.sh` for only the approved connection. Test one read before
   proposing any write.
9. Store business context, paid training, contracts, partner lists, and exports
   only under `~/.hermes/affiliate-manager/private-business/`.
10. Run `./orgo/verify.sh`, complete the synthetic test in `START-HERE.md`, and
    prove one authorized reply.

## Why the runtime is pinned

The repository installs Hermes v0.21.0 from the exact signed release tag,
commit, and reviewed installer checksum in `orgo/deployment.json`. A floating
`main` or `latest` can change between installations. Updates are reviewed and
then pinned so every recipient gets the same tested build.

## Connections

The core installation needs no CRM or affiliate-platform credential. Add them
after the agent answers correctly.

- Slack uses Socket Mode, both app and bot tokens, and an owner Member-ID
  allowlist.
- Telegram uses the normal bot-token flow.
- CRM, calendar, inbox, documents, and supported affiliate tools can be added
  through a private Composio connection. The MCP is marked untrusted so Hermes'
  manual approval applies.
- Instantly is limited to inbox review, classification, and draft preparation by
  the included workflow. It does not send the draft.
- A platform that is not supported through an official API or authorized
  connector stays disconnected until a reviewed integration exists.

## Completion card

The setup agent reports:

- computer name and status;
- exact Hermes version and commit;
- chosen model provider, without the secret;
- connected channels and tools, with the test performed for each;
- static and live verification result;
- synthetic workflow result;
- what remains intentionally disconnected;
- the emergency-stop command.

Do not describe the installation as complete when the model has not answered or
the selected channel has not replied.
