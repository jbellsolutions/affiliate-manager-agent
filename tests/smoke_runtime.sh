#!/usr/bin/env bash
# Boot the exact reviewed image with the rendered Affiliate Manager profile.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="nousresearch/hermes-agent:v2026.8.31@sha256:64923faeae267792bf9bf87fe3b4c4869e35004e360c7df01730ad801b74d524"
RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/affiliate-manager-runtime.XXXXXX")"
CONTAINER_NAME="affiliate-manager-runtime-smoke-$$"
cleanup() {
  if [[ "$CONTAINER_NAME" == affiliate-manager-runtime-smoke-* ]]; then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
  [ -n "$RUNTIME_DIR" ] && [ -d "$RUNTIME_DIR" ] &&
    [[ "$(basename "$RUNTIME_DIR")" == affiliate-manager-runtime.* ]] &&
    rm -rf -- "$RUNTIME_DIR"
}
trap cleanup EXIT

mkdir -p "$RUNTIME_DIR/data"
cp "$ROOT/files/SOUL.md" "$RUNTIME_DIR/data/SOUL.md"
cp "$ROOT/files/AGENTS.md" "$RUNTIME_DIR/data/AGENTS.md"
sed -e 's#__AGENT_PERSONA__#concise#g' \
    -e 's#__SLACK_ENABLED__#false#g' \
    -e 's#__TELEGRAM_ENABLED__#false#g' \
    -e 's#__TELEGRAM_HOME_CHANNEL__##g' \
    -e 's#__SLACK_HOME_CHANNEL__##g' \
    "$ROOT/hermes/config.template.yaml" > "$RUNTIME_DIR/data/config.yaml"
sed -i.bak '/__OPENROUTER_FALLBACK_START__/,/__OPENROUTER_FALLBACK_END__/d' "$RUNTIME_DIR/data/config.yaml"
rm -f -- "$RUNTIME_DIR/data/config.yaml.bak"
chmod 600 "$RUNTIME_DIR/data/config.yaml"

docker run -d \
  --name "$CONTAINER_NAME" \
  -e FIREWORKS_API_KEY=fw_placeholder \
  -e HERMES_ACCEPT_HOOKS=0 \
  -e HOME=/opt/data \
  -e HERMES_TUI_DIR=/opt/hermes/ui-tui \
  -v "$RUNTIME_DIR/data:/opt/data" \
  -v "$ROOT/bin/start-hermes.sh:/start-hermes.sh:ro" \
  -v "$ROOT/bin/init-chown.sh:/init-chown.sh:ro" \
  --security-opt no-new-privileges:true \
  --entrypoint /init-chown.sh \
  "$IMAGE" /bin/bash /start-hermes.sh >/dev/null

for attempt in $(seq 1 18); do
  if docker exec "$CONTAINER_NAME" /opt/hermes/.venv/bin/hermes gateway status >/dev/null 2>&1; then
    break
  fi
  if [ "$attempt" -eq 18 ]; then
    docker logs "$CONTAINER_NAME" --tail=150 >&2
    echo "The reviewed runtime did not become ready." >&2
    exit 1
  fi
  sleep 5
done

version="$(docker exec "$CONTAINER_NAME" /opt/hermes/.venv/bin/hermes --version)"
[[ "$version" == *"Hermes Agent v0.21.0"* ]]
[ "$(docker exec "$CONTAINER_NAME" /opt/hermes/.venv/bin/hermes config get approvals.mode)" = "manual" ]
[ "$(docker exec "$CONTAINER_NAME" /opt/hermes/.venv/bin/hermes config get approvals.cron_mode)" = "deny" ]
[ "$(docker exec "$CONTAINER_NAME" /opt/hermes/.venv/bin/hermes config get hooks_auto_accept)" = "false" ]

echo "Reviewed Hermes runtime smoke test passed."
