#!/usr/bin/env bash
# Plain-language connection menu for Affiliate Manager on Orgo.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
ENV_FILE="$HERMES_HOME/.env"
STOP_FILE="$HERMES_HOME/affiliate-manager/state/EXTERNAL_WRITES_STOPPED"
mkdir -p "$HERMES_HOME"
touch "$ENV_FILE"
chmod 600 "$ENV_FILE"

secret() { local value; read -r -s -p "$1: " value; printf '\n' >&2; printf '%s' "$value"; }
fail() { printf 'Connection stopped: %s\n' "$*" >&2; exit 1; }
upsert() {
  local key=$1 value=$2 temporary
  [[ "$value" != *$'\n'* ]] || fail "a private value cannot contain a new line"
  temporary="$(mktemp "$HERMES_HOME/.env.tmp.XXXXXX")"
  awk -v key="$key" 'index($0, key "=") != 1 { print }' "$ENV_FILE" > "$temporary"
  printf '%s=%s\n' "$key" "$value" >> "$temporary"
  chmod 600 "$temporary"
  mv "$temporary" "$ENV_FILE"
}
restart_gateway() {
  hermes gateway install >/dev/null
  hermes gateway restart >/dev/null 2>&1 || hermes gateway start >/dev/null
}
enable_composio_toolsets() {
  hermes config set toolsets '["hermes-cli","mcp-composio"]' >/dev/null
  hermes config set platform_toolsets.cli '["hermes-cli","mcp-composio"]' >/dev/null
  hermes config set platform_toolsets.slack '["hermes-slack","browser","clarify","code_execution","computer_use","cronjob","delegation","file","kanban","memory","mcp-composio","session_search","skills","terminal","todo","vision","web"]' >/dev/null
  hermes config set platform_toolsets.telegram '["hermes-telegram","browser","clarify","code_execution","computer_use","cronjob","delegation","file","kanban","memory","mcp-composio","session_search","skills","terminal","todo","vision","web"]' >/dev/null
}

cat <<'MENU'
Connect Affiliate Manager

  1. Slack
  2. Telegram
  3. CRM, affiliate platform, calendar, inboxes, files, and other apps
  4. Instantly reply triage and draft preparation
  5. Show connection status
MENU
read -r -p "Choose 1 through 5: " choice
case "$choice" in
  1)
    echo "Create the Slack app from slack/manifest.example.json in this repository."
    echo "Install it, enable Socket Mode, then create an app-level connections:write token."
    bot="$(secret "Paste the xoxb- Bot Token")"
    app="$(secret "Paste the xapp- App Token")"
    [[ "$bot" == xoxb-* ]] || fail "the Bot Token must start with xoxb-"
    [[ "$app" == xapp-* ]] || fail "the App Token must start with xapp-"
    read -r -p "Paste the owner's Slack Member ID: " allowed
    allowed="${allowed//[[:space:]]/}"
    [[ "$allowed" =~ ^[UW][A-Z0-9]+(,[UW][A-Z0-9]+)*$ ]] || fail "that Member ID is not valid"
    upsert SLACK_BOT_TOKEN "$bot"
    upsert SLACK_APP_TOKEN "$app"
    upsert SLACK_ALLOWED_USERS "$allowed"
    unset bot app
    hermes config set gateway.platforms.slack.enabled true >/dev/null
    restart_gateway
    echo "Slack is connected. Send hello, then verify the reply."
    ;;
  2)
    echo "Create the bot in Telegram with @BotFather, then copy its token."
    token="$(secret "Paste the Telegram bot token")"
    [[ "$token" == *:* ]] || fail "that does not look like a Telegram bot token"
    upsert TELEGRAM_BOT_TOKEN "$token"
    unset token
    hermes config set gateway.platforms.telegram.enabled true >/dev/null
    restart_gateway
    echo "Telegram is connected. Send hello, then verify the reply."
    ;;
  3)
    [ ! -f "$STOP_FILE" ] || fail "external tools are stopped; review the stop record before connecting"
    echo "Open https://app.composio.dev and copy a consumer key beginning ck_."
    echo "Connect only the intended accounts and grant the narrowest available access."
    value="$(secret "Paste the ck_ consumer key")"
    [[ "$value" == ck_* ]] || fail "the consumer key must begin with ck_"
    upsert COMPOSIO_API_KEY "$value"
    unset value
    hermes config set mcp_servers.composio.url https://connect.composio.dev/mcp >/dev/null
    hermes config set mcp_servers.composio.headers.x-consumer-api-key '${COMPOSIO_API_KEY}' >/dev/null
    hermes config set mcp_servers.composio.trust untrusted >/dev/null
    hermes config set mcp_servers.composio.timeout 180 >/dev/null
    hermes config set mcp_servers.composio.enabled true >/dev/null
    enable_composio_toolsets
    restart_gateway
    echo "Business apps are connected behind manual approval. Test one read-only request first."
    ;;
  4)
    echo "This connection supports inbox review, classification, and draft preparation."
    echo "The included workflow does not send replies."
    value="$(secret "Paste the Instantly API key")"
    [ -n "$value" ] || fail "the Instantly key cannot be blank"
    upsert INSTANTLY_API_KEY "$value"
    unset value
    echo "Instantly is ready for a read-only/draft test with synthetic data first."
    ;;
  5)
    hermes status || true
    hermes mcp list || true
    hermes gateway status || true
    ;;
  *) fail "choose a number from 1 through 5" ;;
esac
