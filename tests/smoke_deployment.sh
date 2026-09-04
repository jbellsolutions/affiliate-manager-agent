#!/usr/bin/env bash
# Stamp a secret-free deployment into an isolated temporary directory and inspect it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/affiliate-manager-smoke.XXXXXX")"
cleanup() {
  [ -n "$SMOKE_DIR" ] && [ -d "$SMOKE_DIR" ] &&
    [ "$(basename "$SMOKE_DIR")" != "." ] &&
    [[ "$(basename "$SMOKE_DIR")" == affiliate-manager-smoke.* ]] &&
    rm -rf -- "$SMOKE_DIR"
}
trap cleanup EXIT

PRIVATE_CONFIG="$SMOKE_DIR/agent.env"
cat > "$PRIVATE_CONFIG" <<EOF
AGENT_NAME=affiliate-manager-smoke
BASE_DIR=$SMOKE_DIR
HERMES_PORT=18789
TZ=America/New_York
AGENT_PERSONA=concise
TELEGRAM_HOME_CHANNEL=
SLACK_HOME_CHANNEL=
FIREWORKS_API_KEY=fw_placeholder
TOGETHER_API_KEY=tgp_v1_placeholder
OPENROUTER_API_KEY=
SLACK_BOT_TOKEN=
SLACK_APP_TOKEN=
SLACK_ALLOWED_USERS=
TELEGRAM_BOT_TOKEN=
GATEWAY_ALLOW_ALL_USERS=false
HERMES_MEM_LIMIT=5g
HERMES_CPUS=3.0
EOF
chmod 600 "$PRIVATE_CONFIG"

"$ROOT/new-agent.sh" "$PRIVATE_CONFIG" >/dev/null

required=(
  "compose.yml"
  "bin/init-chown.sh"
  "bin/start-hermes.sh"
  "bin/watchdog.sh"
  "hermes/data/AGENTS.md"
  "hermes/data/SOUL.md"
  "hermes/data/config.yaml"
  "hermes/data/skills/roles/affiliate-manager/SKILL.md"
  "hermes/data/skills/sales/instantly-cold-email/SKILL.md"
  "hermes/data/affiliate-manager/policies/permissions.json"
  "hermes/data/affiliate-manager/routines/daily-partner-pipeline.prompt"
  "hermes/data/affiliate-manager/tools/instantly_reply_daemon.py"
)
for relative in "${required[@]}"; do
  [ -f "$SMOKE_DIR/$relative" ] || {
    echo "Missing deployed file: $relative" >&2
    exit 1
  }
done

file_mode() {
  python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777)[2:])' "$1"
}
[ "$(file_mode "$SMOKE_DIR/.env")" = "600" ]
[ "$(file_mode "$SMOKE_DIR/hermes/data/config.yaml")" = "600" ]
[ "$(file_mode "$SMOKE_DIR/hermes/data/affiliate-manager/private-business")" = "700" ]
grep -q 'mode: manual' "$SMOKE_DIR/hermes/data/config.yaml"
grep -q 'cron_mode: deny' "$SMOKE_DIR/hermes/data/config.yaml"
grep -q 'hooks_auto_accept: false' "$SMOKE_DIR/hermes/data/config.yaml"
grep -q 'entrypoint-dispatch.sh' "$SMOKE_DIR/bin/init-chown.sh"

echo "Deployment layout smoke test passed."
