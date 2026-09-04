#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Checking shell scripts..."
while IFS= read -r script; do
  bash -n "$script"
done < <(find . -type f -name '*.sh' -not -path './.git/*' | sort)

echo "Checking Python files..."
python3 -m compileall -q scripts tests sync orgo

echo "Checking structured configuration..."
python3 -m json.tool orgo/deployment.json >/dev/null
python3 -m json.tool policies/permissions.json >/dev/null
python3 -m json.tool slack/manifest.example.json >/dev/null
python3 -m json.tool grok-bot/manifest.json >/dev/null

echo "Running repository tests..."
python3 -m unittest discover -s tests -p 'test_*.py' -v

echo "Checking a fresh secret-free deployment layout..."
./tests/smoke_deployment.sh

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "Checking Compose configuration..."
  FIREWORKS_API_KEY=fw_placeholder \
  AGENT_NAME=affiliate-manager \
  BASE_DIR=/srv/affiliate-manager \
    docker compose -f compose.yml config --quiet
fi

echo "Verification passed."
