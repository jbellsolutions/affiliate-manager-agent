#!/usr/bin/env bash
# Install the public Affiliate Manager profile on an Orgo Linux computer.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
HERMES_TAG="v2026.8.31"
HERMES_COMMIT="29112bef099274229cadff79cdff7bf7b99c4b77"
INSTALLER_SHA256="85ef536d455e51ab67aa74d79272efd49fe717597dbaadfd3cca179a905f4706"

say() { printf '\n%s\n' "$*"; }
fail() { printf '\nSetup stopped: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || fail "this installer belongs on the Orgo Linux computer"
if [ "$(id -u)" -eq 0 ]; then
  ELEVATE=()
else
  command -v sudo >/dev/null 2>&1 || fail "this account needs administrator access"
  ELEVATE=(sudo)
fi

say "Affiliate Manager for Orgo"
echo "This installs the agent profile and safe operating defaults."
echo "Private account connections stay on this computer and never enter GitHub."

say "1 of 5 — Checking the computer"
if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  "${ELEVATE[@]}" apt-get update -qq
  "${ELEVATE[@]}" apt-get install -y -qq ca-certificates curl git python3
fi

installed_commit=""
for candidate in /opt/hermes /usr/local/lib/hermes-agent "$HERMES_HOME/hermes-agent"; do
  if [ -d "$candidate/.git" ]; then
    installed_commit="$(git -C "$candidate" rev-parse HEAD 2>/dev/null || true)"
    [ "$installed_commit" = "$HERMES_COMMIT" ] && break
  fi
done
if [ "$installed_commit" != "$HERMES_COMMIT" ]; then
  say "2 of 5 — Installing the reviewed Hermes v0.21.0 release"
  installer="$(mktemp)"
  cleanup() { rm -f -- "${installer:-}"; }
  trap cleanup EXIT
  curl -fsSL "https://raw.githubusercontent.com/NousResearch/hermes-agent/$HERMES_COMMIT/scripts/install.sh" -o "$installer"
  actual_sha="$(sha256sum "$installer" | awk '{print $1}')"
  [ "$actual_sha" = "$INSTALLER_SHA256" ] || fail "the Hermes installer checksum did not match the reviewed release"
  bash "$installer" --skip-setup --branch "$HERMES_TAG" --commit "$HERMES_COMMIT" --force-commit
  cleanup
  trap - EXIT
else
  say "2 of 5 — The reviewed Hermes release is already installed"
fi
command -v hermes >/dev/null 2>&1 || fail "Hermes did not install correctly"

say "3 of 5 — Installing the Affiliate Manager profile and skills"
python3 "$REPO_DIR/orgo/sync_seed.py" "$REPO_DIR" "$HERMES_HOME"
chmod 700 "$HERMES_HOME" "$HERMES_HOME/affiliate-manager/state" "$HERMES_HOME/affiliate-manager/private-business"
chmod 600 "$HERMES_HOME/SOUL.md" "$HERMES_HOME/AGENTS.md" 2>/dev/null || true

say "4 of 5 — Applying current safety, memory, and reliability settings"
for setting in \
  'toolsets=["hermes-cli"]' \
  'platform_toolsets.cli=["hermes-cli"]' \
  'platform_toolsets.slack=["hermes-slack","browser","clarify","code_execution","computer_use","cronjob","delegation","file","kanban","memory","session_search","skills","terminal","todo","vision","web"]' \
  'platform_toolsets.telegram=["hermes-telegram","browser","clarify","code_execution","computer_use","cronjob","delegation","file","kanban","memory","session_search","skills","terminal","todo","vision","web"]' \
  'agent.max_turns=60' \
  'agent.gateway_timeout=1800' \
  'agent.restart_drain_timeout=60' \
  'agent.api_max_retries=3' \
  'agent.tool_use_enforcement=auto' \
  'agent.verify_on_stop=true' \
  'browser.inactivity_timeout=120' \
  'browser.command_timeout=30' \
  'browser.record_sessions=false' \
  'browser.allow_private_urls=false' \
  'checkpoints.enabled=true' \
  'checkpoints.max_snapshots=50' \
  'checkpoints.retention_days=7' \
  'memory.memory_enabled=true' \
  'memory.user_profile_enabled=true' \
  'memory.nudge_interval=10' \
  'skills.creation_nudge_interval=15' \
  'skills.write_approval=true' \
  'skills.guard_agent_created=true' \
  'approvals.mode=manual' \
  'approvals.timeout=120' \
  'approvals.cron_mode=deny' \
  'approvals.mcp_reload_confirm=true' \
  'approvals.destructive_slash_confirm=true' \
  'hooks_auto_accept=false' \
  'privacy.redact_pii=true' \
  'security.allow_private_urls=false' \
  'security.redact_secrets=true' \
  'security.tirith_enabled=true' \
  'security.tirith_fail_open=false' \
  'tool_loop_guardrails.hard_stop_enabled=true' \
  'compression.tail_mode=lean' \
  'cron.wrap_response=true' \
  'kanban.dispatch_in_gateway=true' \
  'kanban.dispatch_interval_seconds=60' \
  'delegation.inherit_mcp_toolsets=true' \
  'delegation.subagent_auto_approve=false' \
  'delegation.max_spawn_depth=1'; do
  key=${setting%%=*}
  value=${setting#*=}
  hermes config set "$key" "$value" >/dev/null
done

mkdir -p "$HOME/Desktop"
install -m 0755 "$REPO_DIR/orgo/AffiliateManager.desktop" "$HOME/Desktop/AffiliateManager.desktop"
install -m 0755 "$REPO_DIR/orgo/AffiliateManagerSetup.desktop" "$HOME/Desktop/AffiliateManagerSetup.desktop"
chmod +x "$REPO_DIR/orgo/connect.sh" "$REPO_DIR/orgo/emergency-stop.sh" "$REPO_DIR/orgo/resume-external-writes.sh" "$REPO_DIR/orgo/verify.sh"

say "5 of 5 — Verifying the installation"
"$REPO_DIR/orgo/verify.sh" --allow-unconnected

cat <<'TEXT'

Affiliate Manager is installed on this Orgo computer.

Next:
  hermes setup             Connect the model privately when needed
  ./orgo/connect.sh        Connect a channel or approved business app
  hermes                   Open the agent in this terminal
  ./orgo/emergency-stop.sh "reason"  Freeze connected external-write tools

The same launch and connection choices are available from the desktop icons.
TEXT
