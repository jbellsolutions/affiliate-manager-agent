#!/usr/bin/env bash
# provision-vps.sh — prepare a fresh Ubuntu 22.04+ VPS to host an Affiliate Manager.
# Installs Docker (+ compose plugin) and clones this repository. Run as a sudo user.
#
#   curl -fsSL https://raw.githubusercontent.com/jbellsolutions/affiliate-manager-agent/main/provision-vps.sh | bash
#   # then:  cd ~/affiliate-manager-agent && ./setup.sh
set -euo pipefail

REPO="${AFFILIATE_MANAGER_REPO:-https://github.com/jbellsolutions/affiliate-manager-agent.git}"
DEST="${AFFILIATE_MANAGER_DEST:-$HOME/affiliate-manager-agent}"

echo "▸ Affiliate Manager VPS provisioner"
# Works as root (fresh DO/Hetzner droplet) or as a sudo user.
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# ── Docker ────────────────────────────────────────────────────────────────────
if ! command -v docker >/dev/null 2>&1; then
  echo "  · installing Docker..."
  curl -fsSL https://get.docker.com | $SUDO sh
  # If running as a normal user, add to the docker group so `docker` works without sudo.
  [ -n "$SUDO" ] && { $SUDO usermod -aG docker "$USER"; echo "  · added $USER to docker group (run 'newgrp docker' or re-login)"; }
fi
docker compose version >/dev/null 2>&1 || { echo "  · installing compose plugin..."; $SUDO apt-get update -qq && $SUDO apt-get install -y -qq docker-compose-plugin; }
$SUDO systemctl enable --now docker >/dev/null 2>&1 || true

# ── git + template ────────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || { $SUDO apt-get update -qq && $SUDO apt-get install -y -qq git; }
if [ -d "$DEST/.git" ]; then
  echo "  · updating $DEST"; git -C "$DEST" pull --ff-only || true
else
  echo "  · cloning template to $DEST"; git clone "$REPO" "$DEST"
fi

# ── optional: tailscale for private UI access ─────────────────────────────────
if ! command -v tailscale >/dev/null 2>&1; then
  echo "  · (optional) install Tailscale for private UI access:"
  echo "      curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up"
fi

cat <<EOF

✅ VPS ready. Next:
  cd $DEST
  ./setup.sh

The guided installer explains what it needs, collects private values without
echoing them, installs the agent, starts it, waits for health, and verifies the
reviewed runtime. One VPS can host multiple agents with distinct names and ports.
EOF
