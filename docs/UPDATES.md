# Runtime and update policy

## Current reviewed baseline

Reviewed on 2026-09-04:

- Hermes Agent v0.21.0
- Release tag `v2026.8.31`
- Commit `29112bef099274229cadff79cdff7bf7b99c4b77`
- Multi-platform Docker image digest
  `sha256:64923faeae267792bf9bf87fe3b4c4869e35004e360c7df01730ad801b74d524`
- Installer SHA-256
  `85ef536d455e51ab67aa74d79272efd49fe717597dbaadfd3cca179a905f4706`
- Orgo base `system/hermes-agent@1.0.0`
- Orgo Hermes sizing baseline: 8 GB RAM and 4 CPU cores

Sources:

- <https://github.com/NousResearch/hermes-agent/releases/tag/v2026.8.31>
- <https://docs.orgo.ai/guides/hermes>
- <https://docs.orgo.ai/llms.txt>

## Included current capabilities

The configuration uses the current Hermes approval, redaction, checkpoint,
memory, browser, verification-on-stop, loop-stop, delegation, cron, and gateway
settings introduced or maintained by the reviewed release. Agent-authored skill
changes require review. Cron cannot approve external work. Business-app MCP
connections are untrusted.

## Updating safely

Do not change the tag, commit, image digest, or installer checksum independently.
For a new Hermes release:

1. Read the official release notes and security changes.
2. Resolve the signed tag to its exact commit.
3. capture the multi-platform Docker digest and installer SHA-256.
4. Test a clean Orgo install, a clean Docker configuration, model setup, a
   private channel, manual approvals, secret redaction, and emergency stop.
5. Update every pin together and run `./scripts/verify.sh`.
6. Release to one non-production canary before broad rollout.

Recipients receive repository updates only when the reviewed pins and tests move
together. The installer never silently follows an unreviewed `latest` build.
