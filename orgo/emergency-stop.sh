#!/usr/bin/env bash
# Freeze connected business-app actions while preserving analysis and drafts.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
STATE_DIR="$HERMES_HOME/affiliate-manager/state"
STOP_FILE="$STATE_DIR/EXTERNAL_WRITES_STOPPED"
mkdir -p "$STATE_DIR"
reason="${*:-Owner emergency stop}"
timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
temporary="$(mktemp "$STATE_DIR/stop.XXXXXX")"
printf '%s | human-owner | %s\n' "$timestamp" "$reason" > "$temporary"
chmod 600 "$temporary"
mv "$temporary" "$STOP_FILE"
if command -v hermes >/dev/null 2>&1; then
  hermes config set approvals.cron_mode deny >/dev/null 2>&1 || true
  hermes config set mcp_servers.composio.enabled false >/dev/null 2>&1 || true
  hermes gateway restart >/dev/null 2>&1 || true
fi
echo "External business-app actions are stopped. Research and drafting remain available."
