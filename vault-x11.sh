#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# Crypto Vault — X11 Mode (native rendering)
# Runs Chrome directly on your desktop via X11.
# No VNC = no blur, no compression, no disconnects.
#
# Supports: Linux, WSL2 (WSLg), macOS (XQuartz)
#
# Delegates orchestration (proxy start, health wait, volumes,
# networks) to `docker compose run --rm crypto-vault`, using the
# `vault` profile defined in docker-compose.yml.
# ─────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Platform detection: set DISPLAY + xhost authorisation ──
case "$(uname -s)" in
    Darwin)
        # macOS — requires XQuartz (brew install --cask xquartz)
        if ! command -v xquartz &>/dev/null \
           && [ ! -d /Applications/Utilities/XQuartz.app ]; then
            echo "Error: XQuartz is required. Install with: brew install --cask xquartz"
            exit 1
        fi
        # Allow the container (via host.docker.internal) to connect to XQuartz
        xhost +localhost &>/dev/null || true
        export DISPLAY="host.docker.internal:0"
        ;;
    Linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            # WSL2 — WSLg provides the X server; DISPLAY is already set
            export DISPLAY="${DISPLAY:-:0}"
        else
            # Native Linux — grant local Docker access to the X server
            xhost +local:docker &>/dev/null || true
            export DISPLAY="${DISPLAY:-:0}"
        fi
        ;;
    *)
        echo "Error: unsupported platform $(uname -s)"
        exit 1
        ;;
esac

# ── Build image if missing (compose doesn't auto-build on `run`) ──
if ! docker image inspect crypto-safe-container:latest >/dev/null 2>&1; then
    echo "Building vault image (first run only)..."
    docker compose --profile vault build crypto-vault
fi

# ── Clear stale Chrome profile lock from a previous crash ──
docker run --rm -v crypto-vault-chrome:/data busybox \
    rm -f /data/SingletonLock /data/SingletonSocket /data/SingletonCookie \
    2>/dev/null || true

echo "Launching Crypto Vault..."

# `docker compose run` handles:
#   - starting egress-proxy (via depends_on)
#   - waiting for proxy health (condition: service_healthy)
#   - attaching vault-internal network + DNS
#   - mounting volumes + X11 socket
# `--rm` removes the container on exit.
exec docker compose --profile vault run --rm crypto-vault \
    chromium \
    --no-sandbox \
    --password-store=basic \
    --proxy-server=http://172.30.0.2:3128 \
    --no-first-run \
    --disable-search-engine-choice-screen \
    file:///opt/chrome-extensions/welcome.html
