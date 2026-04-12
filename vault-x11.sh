#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# Crypto Vault — X11 Mode (native rendering)
# Runs Chrome directly on your desktop via X11.
# No VNC = no blur, no compression, no disconnects.
#
# Supports: Linux, WSL2 (WSLg), macOS (XQuartz)
# ─────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Detect platform and set X11 socket / DISPLAY ──
X11_MOUNT="/tmp/.X11-unix:/tmp/.X11-unix:ro"
EXTRA_ARGS=()

case "$(uname -s)" in
    Darwin)
        # macOS — requires XQuartz (brew install --cask xquartz)
        if ! command -v xquartz &>/dev/null && [ ! -d /Applications/Utilities/XQuartz.app ]; then
            echo "Error: XQuartz is required. Install with: brew install --cask xquartz"
            exit 1
        fi
        # Allow container to connect to XQuartz
        xhost +localhost &>/dev/null || true
        DISPLAY="host.docker.internal:0"
        X11_MOUNT="/tmp/.X11-unix:/tmp/.X11-unix:ro"
        EXTRA_ARGS+=("--add-host=host.docker.internal:host-gateway")
        ;;
    Linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            # WSL2 — uses WSLg's X server
            DISPLAY="${DISPLAY:-:0}"
        else
            # Native Linux
            DISPLAY="${DISPLAY:-:0}"
            xhost +local:docker &>/dev/null || true
        fi
        ;;
esac

# ── Ensure proxy is running ──
if ! docker compose ps egress-proxy --format '{{.Status}}' 2>/dev/null | grep -q 'Up'; then
    echo "Starting egress proxy..."
    docker compose up -d egress-proxy
    sleep 3
fi

# ── Remove stale Chrome profile lock ──
docker run --rm -v crypto-vault-chrome:/data busybox \
    rm -f /data/SingletonLock /data/SingletonSocket /data/SingletonCookie 2>/dev/null || true

echo "Launching Crypto Vault..."

docker run --rm -it \
    --name crypto-vault-x11 \
    --network crypto-safe-container_vault-internal \
    --ip 172.30.0.10 \
    --dns 172.30.0.2 \
    -e DISPLAY="$DISPLAY" \
    -v "$X11_MOUNT" \
    -v crypto-vault-chrome:/home/kasm-user/.config/google-chrome \
    -v crypto-vault-downloads:/home/kasm-user/Downloads \
    -v crypto-vault-projects:/home/kasm-user/projects \
    --shm-size=512m \
    --cap-drop ALL \
    --security-opt no-new-privileges:true \
    "${EXTRA_ARGS[@]}" \
    --entrypoint bash \
    crypto-safe-container-crypto-vault \
    -c '
        exec /opt/google/chrome/google-chrome \
            --no-sandbox \
            --password-store=basic \
            --proxy-server=http://172.30.0.2:3128 \
            --no-first-run \
            --disable-search-engine-choice-screen \
            file:///opt/chrome-extensions/welcome.html \
            "$@"
    '
