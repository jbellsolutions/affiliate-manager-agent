#!/usr/bin/env bash
# Relationship cards in the exact reviewed Hermes image, the way an Orgo computer runs them: a non-root desktop user
# runs the relationship block of orgo/setup.sh, Hermes loads the relcore MCP server and lists its tools, and the
# sample program becomes cards in the vault. Nothing leaves the container; only the container it starts is removed.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="nousresearch/hermes-agent:v2026.8.31@sha256:64923faeae267792bf9bf87fe3b4c4869e35004e360c7df01730ad801b74d524"
docker image inspect "$IMAGE" >/dev/null 2>&1 || docker pull "$IMAGE" >/dev/null
docker run --rm -i -v "$ROOT:/src:ro" --entrypoint bash "$IMAGE" -s <<'IN'
set -euo pipefail
useradd -m -s /bin/bash orgo
mkdir -p /home/orgo/affiliate-manager-agent
cd /src && tar --exclude=.git --exclude=__pycache__ -cf - . | tar -xf - -C /home/orgo/affiliate-manager-agent
chown -R orgo:orgo /home/orgo
cat > /tmp/inner.sh <<'SH'
set -euo pipefail
export PATH="/opt/hermes/.venv/bin:$PATH" HOME=/home/orgo HERMES_HOME=/home/orgo/.hermes
REPO_DIR=/home/orgo/affiliate-manager-agent
mkdir -p "$HERMES_HOME/affiliate-manager/state" "$HERMES_HOME/affiliate-manager/private-business"
say() { printf '%s\n' "$*"; }
fail=0
t() { if eval "$2"; then echo "  ok    $1"; else echo "  FAIL  $1"; fail=1; fi; }
eval "$(sed -n '/# --- relationship cards: begin/,/# --- relationship cards: end/p' "$REPO_DIR/orgo/setup.sh")"
t "Hermes has the relcore server" '[ "$(hermes config get mcp_servers.relcore.command)" = python3 ]'
hermes mcp test relcore > /tmp/mcp-test.txt 2>&1 || true
t "Hermes connects to relcore and lists its tools" 'grep -q rel_context /tmp/mcp-test.txt && grep -q rel_sent_record /tmp/mcp-test.txt'
t "no approve, send, sign, decide or release tool" '! grep -oE "rel_[a-z_]+" /tmp/mcp-test.txt | grep -qE "approve|send|sign|decide|release|resume|purge"'
"$REPO_DIR/orgo/relationship.sh" import apply csv "$REPO_DIR/examples/relationship" --client "Northwind Outdoor Gear" > /tmp/import.json
t "the sample became cards in the vault" '[ "$(ls ~/AffiliateVault/People | wc -l)" -ge 7 ] && [ "$(ls ~/AffiliateVault/Partnerships | wc -l)" -ge 6 ]'
t "the index is private" '[ "$(stat -c %a "$HERMES_HOME/affiliate-manager/private-business/relationship")" = 700 ]'
"$REPO_DIR/orgo/relationship.sh" doctor > /tmp/doctor.txt 2>&1 || true
t "relcore doctor passes" '! grep -q FAIL /tmp/doctor.txt'
[ "$fail" = 0 ] || { cat /tmp/mcp-test.txt /tmp/doctor.txt; exit 1; }
SH
runuser -u orgo -- bash /tmp/inner.sh
IN
echo "Relationship cards smoke test passed ($IMAGE)."
