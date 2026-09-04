#!/usr/bin/env bash
# Owner-only recovery from the Affiliate Manager external-write stop.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
STOP_FILE="$HERMES_HOME/affiliate-manager/state/EXTERNAL_WRITES_STOPPED"
if [ ! -f "$STOP_FILE" ]; then
  echo "No external-write stop is recorded."
  exit 0
fi
echo "Current stop record:"
sed -n '1p' "$STOP_FILE"
read -r -p "Type RESUME AFFILIATE OPERATIONS to continue: " answer
[ "$answer" = "RESUME AFFILIATE OPERATIONS" ] || { echo "Nothing changed."; exit 1; }
rm -f -- "$STOP_FILE"
echo "The stop record is cleared. Reconnect any tool that the stop disabled, then test a read before a write."
