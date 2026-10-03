#!/usr/bin/env bash
# Relationship cards on this Orgo computer: the relcore command line with this install's paths.
# Drafts only: there is no approvals service or sender here, so prepared messages wait in the outbox for you.
#
#   ./orgo/relationship.sh init
#   ./orgo/relationship.sh import plan csv <folder> --client "<business>"     (apply to write the cards)
#   ./orgo/relationship.sh card <email or phone>      ./orgo/relationship.sh context <email or phone>
#   ./orgo/relationship.sh scorecard                  ./orgo/relationship.sh purge <email or phone> [--yes]
#   ./orgo/relationship.sh env                        print the settings the MCP server uses
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
export RELCORE_MODE=plugin
export RELCORE_HOME="${RELCORE_HOME:-$HERMES_HOME/affiliate-manager/private-business/relationship}"
export RELCORE_VAULT="${AFFILIATE_VAULT:-${RELCORE_VAULT:-$HOME/AffiliateVault}}"
export RELCORE_STOP_FILE="$HERMES_HOME/affiliate-manager/state/EXTERNAL_WRITES_STOPPED"
export RELCORE_TAXONOMY="${RELCORE_TAXONOMY:-$REPO_DIR/data/affiliate-partner-types.json}"
export RELCORE_EMPLOYEE="${RELCORE_EMPLOYEE:-default}"
export PYTHONPATH="$REPO_DIR${PYTHONPATH:+:$PYTHONPATH}"
if [ "${1:-}" = "env" ]; then
  for k in RELCORE_MODE RELCORE_HOME RELCORE_VAULT RELCORE_STOP_FILE RELCORE_TAXONOMY RELCORE_EMPLOYEE PYTHONPATH; do
    printf '%s=%s\n' "$k" "${!k}"
  done
  exit 0
fi
exec python3 -m relcore "$@"
