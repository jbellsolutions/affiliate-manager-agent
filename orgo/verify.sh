#!/usr/bin/env bash
set -euo pipefail

ALLOW_UNCONNECTED=false
STATIC_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --allow-unconnected) ALLOW_UNCONNECTED=true ;;
    --static) STATIC_ONLY=true ;;
    *) echo "Unknown verification option: $arg" >&2; exit 2 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
EXPECTED_COMMIT="29112bef099274229cadff79cdff7bf7b99c4b77"

python3 -m json.tool "$REPO_DIR/orgo/deployment.json" >/dev/null
python3 -m json.tool "$REPO_DIR/policies/permissions.json" >/dev/null
find "$REPO_DIR/orgo" -type f -name '*.sh' -print0 | xargs -0 bash -n
python3 -m compileall -q "$REPO_DIR/orgo" "$REPO_DIR/scripts" "$REPO_DIR/tests"
python3 -m unittest discover -s "$REPO_DIR/tests" -p 'test_*.py' -v
"$REPO_DIR/tests/smoke_deployment.sh"

if [ "$STATIC_ONLY" = true ]; then
  echo "Affiliate Manager static verification passed."
  exit 0
fi

[ -f "$HERMES_HOME/SOUL.md" ]
[ -f "$HERMES_HOME/AGENTS.md" ]
[ -f "$HERMES_HOME/skills/roles/affiliate-manager/SKILL.md" ]
[ -f "$HERMES_HOME/affiliate-manager/policies/permissions.json" ]
[ -d "$HERMES_HOME/affiliate-manager/state" ]
[ -d "$HERMES_HOME/affiliate-manager/private-business" ]

installed=""
for candidate in /opt/hermes /usr/local/lib/hermes-agent "$HERMES_HOME/hermes-agent"; do
  if [ -d "$candidate/.git" ]; then
    installed="$(git -C "$candidate" rev-parse HEAD 2>/dev/null || true)"
    [ "$installed" = "$EXPECTED_COMMIT" ] && break
  fi
done
if [ "$installed" != "$EXPECTED_COMMIT" ]; then
  version="$(hermes --version 2>/dev/null || true)"
  [[ "$version" == *"0.21.0"* ]] || {
    echo "Hermes is not the reviewed v0.21.0 runtime." >&2
    exit 1
  }
fi

hermes config get approvals.mode 2>/dev/null | grep -qi manual
hermes config get approvals.cron_mode 2>/dev/null | grep -qi deny
hermes config get hooks_auto_accept 2>/dev/null | grep -qi false
hermes config get privacy.redact_pii 2>/dev/null | grep -qi true
hermes config get security.redact_secrets 2>/dev/null | grep -qi true
hermes config get security.tirith_fail_open 2>/dev/null | grep -qi false
hermes config get tool_loop_guardrails.hard_stop_enabled 2>/dev/null | grep -qi true

if [ "$ALLOW_UNCONNECTED" = false ]; then
  status="$(hermes status 2>/dev/null || true)"
  [ -n "$status" ] || {
    echo "Hermes has not produced a status report." >&2
    exit 1
  }
fi

echo "Affiliate Manager installation verification passed."
