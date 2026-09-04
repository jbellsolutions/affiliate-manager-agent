#!/usr/bin/env bash
# Beginner-first, guided setup for a fresh Ubuntu VPS.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '\n%s\n' "$*"; }
fail() { printf '\nSetup stopped: %s\n' "$*" >&2; exit 1; }
ask() {
  local prompt=$1 default_value=${2:-} answer
  if [ -n "$default_value" ]; then
    read -r -p "$prompt [$default_value]: " answer
    printf '%s' "${answer:-$default_value}"
  else
    read -r -p "$prompt: " answer
    printf '%s' "$answer"
  fi
}
ask_secret() {
  local prompt=$1 answer
  read -r -s -p "$prompt: " answer
  printf '\n' >&2
  printf '%s' "$answer"
}
write_value() {
  local name=$1 value=$2
  printf '%s=%q\n' "$name" "$value" >> "$PRIVATE_CONFIG"
}

say "Affiliate Manager setup"
cat <<'TEXT'
This will install one private, always-on Affiliate Manager on this server.

Before it changes anything, you should have:
  • permission to use this Ubuntu server;
  • one Fireworks AI API key for the hosted model;
  • optionally, Telegram or Slack credentials;
  • your offer, affiliate terms, approved claims, and human approver.

It will install Docker if needed, keep the dashboard private, install the exact
reviewed Hermes v0.21.0 image, create durable private storage, start the agent,
add a health watchdog, and verify the result. Business tools are connected only
after the core agent works.
TEXT
read -r -p "Type INSTALL AFFILIATE MANAGER to continue: " consent
[ "$consent" = "INSTALL AFFILIATE MANAGER" ] || fail "nothing was changed"

[ "$(uname -s)" = "Linux" ] || fail "run this fallback installer on an Ubuntu server; use the Orgo path for a managed computer"
if [ "$(id -u)" -eq 0 ]; then
  ELEVATE=()
else
  command -v sudo >/dev/null 2>&1 || fail "this account needs sudo access"
  ELEVATE=(sudo)
fi

say "1 of 6 — Checking the server"
if ! command -v git >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v crontab >/dev/null 2>&1; then
  "${ELEVATE[@]}" apt-get update -qq
  "${ELEVATE[@]}" apt-get install -y -qq ca-certificates cron curl git python3
fi
if ! command -v docker >/dev/null 2>&1; then
  docker_installer="$(mktemp)"
  cleanup_installer() { rm -f -- "${docker_installer:-}"; }
  trap cleanup_installer EXIT
  curl -fsSL https://get.docker.com -o "$docker_installer"
  "${ELEVATE[@]}" sh "$docker_installer"
  cleanup_installer
  trap - EXIT
fi
docker compose version >/dev/null 2>&1 || {
  "${ELEVATE[@]}" apt-get update -qq
  "${ELEVATE[@]}" apt-get install -y -qq docker-compose-plugin
}
"${ELEVATE[@]}" systemctl enable --now docker >/dev/null 2>&1 || true

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
elif [ "$(id -u)" -ne 0 ] && "${ELEVATE[@]}" docker info >/dev/null 2>&1; then
  "${ELEVATE[@]}" usermod -aG docker "$(id -un)"
  DOCKER=("${ELEVATE[@]}" docker)
else
  fail "Docker was installed but its service is not available"
fi

available_memory_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
available_cpu="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 0)"
if [ "$available_memory_kb" -lt 7000000 ] || [ "$available_cpu" -lt 4 ]; then
  echo "Warning: the current Hermes baseline is designed for an 8 GB / 4 vCPU host."
  echo "This server reports about $((available_memory_kb / 1024 / 1024)) GB RAM and $available_cpu CPU(s)."
fi

say "2 of 6 — Naming the private agent"
AGENT_NAME="$(ask "Agent name; lowercase letters, numbers, and dashes" "affiliate-manager")"
[[ "$AGENT_NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail "that agent name is not valid"
BASE_DIR="/srv/$AGENT_NAME"
TZ_VALUE="$(ask "Timezone" "America/New_York")"
HERMES_PORT="$(ask "Private dashboard port" "18789")"
[[ "$HERMES_PORT" =~ ^[0-9]{2,5}$ ]] || fail "the dashboard port must be a number"

say "3 of 6 — Connecting the model privately"
echo "Create or open a key at https://fireworks.ai/account/api-keys."
FIREWORKS_API_KEY="$(ask_secret "Paste the Fireworks API key")"
[[ "$FIREWORKS_API_KEY" == fw_* ]] || fail "the Fireworks key should begin with fw_"
echo "Optional fallbacks can be added now or later."
TOGETHER_API_KEY="$(ask_secret "Together key, or press Enter to skip")"
OPENROUTER_API_KEY="$(ask_secret "OpenRouter key, or press Enter to skip")"

say "4 of 6 — Choosing how to talk to it"
echo "0. Private browser dashboard only"
echo "1. Telegram"
echo "2. Slack"
echo "3. Both Telegram and Slack"
CHANNEL_CHOICE="$(ask "Choose 0, 1, 2, or 3" "0")"
TELEGRAM_BOT_TOKEN=""
SLACK_BOT_TOKEN=""
SLACK_APP_TOKEN=""
SLACK_ALLOWED_USERS=""
case "$CHANNEL_CHOICE" in
  1|3)
    echo "Create or open your bot with @BotFather in Telegram."
    TELEGRAM_BOT_TOKEN="$(ask_secret "Paste the Telegram bot token")"
    [[ "$TELEGRAM_BOT_TOKEN" == *:* ]] || fail "that does not look like a Telegram bot token"
    ;;
esac
case "$CHANNEL_CHOICE" in
  2|3)
    echo "Create a Slack app from $REPO_DIR/slack/manifest.example.json and enable Socket Mode."
    SLACK_BOT_TOKEN="$(ask_secret "Paste the xoxb- Slack Bot Token")"
    SLACK_APP_TOKEN="$(ask_secret "Paste the xapp- Slack App Token")"
    [[ "$SLACK_BOT_TOKEN" == xoxb-* ]] || fail "the Bot Token must begin with xoxb-"
    [[ "$SLACK_APP_TOKEN" == xapp-* ]] || fail "the App Token must begin with xapp-"
    echo "In Slack, open your profile, choose the three-dot menu, and copy your Member ID."
    SLACK_ALLOWED_USERS="$(ask "Paste the authorized owner's Member ID; use commas for more than one")"
    SLACK_ALLOWED_USERS="${SLACK_ALLOWED_USERS//[[:space:]]/}"
    [[ "$SLACK_ALLOWED_USERS" =~ ^[UW][A-Z0-9]+(,[UW][A-Z0-9]+)*$ ]] || fail "Slack Member IDs look like U01ABC123"
    ;;
  0|1) ;;
  *) fail "choose 0, 1, 2, or 3" ;;
esac

say "5 of 6 — Saving the private configuration and starting"
"${ELEVATE[@]}" mkdir -p "$BASE_DIR"
if [ "$(id -u)" -ne 0 ]; then
  "${ELEVATE[@]}" chown "$(id -u):$(id -g)" "$BASE_DIR"
fi
PRIVATE_CONFIG="$BASE_DIR/agent.env"
: > "$PRIVATE_CONFIG"
chmod 600 "$PRIVATE_CONFIG"
write_value AGENT_NAME "$AGENT_NAME"
write_value BASE_DIR "$BASE_DIR"
write_value HERMES_PORT "$HERMES_PORT"
write_value TZ "$TZ_VALUE"
write_value AGENT_PERSONA "concise"
write_value TELEGRAM_HOME_CHANNEL ""
write_value SLACK_HOME_CHANNEL ""
write_value FIREWORKS_API_KEY "$FIREWORKS_API_KEY"
write_value TOGETHER_API_KEY "$TOGETHER_API_KEY"
write_value OPENROUTER_API_KEY "$OPENROUTER_API_KEY"
write_value SLACK_BOT_TOKEN "$SLACK_BOT_TOKEN"
write_value SLACK_APP_TOKEN "$SLACK_APP_TOKEN"
write_value SLACK_ALLOWED_USERS "$SLACK_ALLOWED_USERS"
write_value TELEGRAM_BOT_TOKEN "$TELEGRAM_BOT_TOKEN"
write_value GATEWAY_ALLOW_ALL_USERS "false"
write_value HERMES_MEM_LIMIT "5g"
write_value HERMES_CPUS "3.0"

"$REPO_DIR/scripts/verify.sh"
"$REPO_DIR/new-agent.sh" "$PRIVATE_CONFIG"
cd "$BASE_DIR"
"${DOCKER[@]}" compose up -d

watchdog_line="* * * * * $BASE_DIR/bin/watchdog.sh"
cron_file="$(mktemp)"
crontab -l 2>/dev/null | grep -Fv "$BASE_DIR/bin/watchdog.sh" > "$cron_file" || true
printf '%s\n' "$watchdog_line" >> "$cron_file"
crontab "$cron_file"
rm -f -- "$cron_file"

say "6 of 6 — Waiting for a healthy agent"
for attempt in $(seq 1 30); do
  health="$("${DOCKER[@]}" inspect "$AGENT_NAME" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' 2>/dev/null || true)"
  if [ "$health" = "healthy" ]; then
    break
  fi
  if [ "$attempt" -eq 30 ]; then
    "${DOCKER[@]}" compose logs --tail=100 hermes
    fail "the agent did not become healthy; recent logs are shown above"
  fi
  sleep 10
done

"${DOCKER[@]}" exec "$AGENT_NAME" /opt/hermes/.venv/bin/hermes --version
"${DOCKER[@]}" compose ps

cat <<EOF

Affiliate Manager is running.

Private dashboard:
  ssh -L $HERMES_PORT:127.0.0.1:$HERMES_PORT <this-server>
  then open http://localhost:$HERMES_PORT

Private business context lives at:
  $BASE_DIR/hermes/data/affiliate-manager/private-business/

Start with the synthetic assignment in START-HERE.md. Connect business systems
only after the first response is correct. The Orgo connection menu is not used
for this Docker installation; add hosted integrations through the private
dashboard and keep manual approval enabled.
EOF
