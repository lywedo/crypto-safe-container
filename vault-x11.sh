#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# Crypto Vault — X11 Mode (native rendering)
# Runs Chrome directly on your desktop via X11.
# No VNC = no blur, no compression, no disconnects.
# ─────────────────────────────────────────────────

# Ensure proxy is running
if ! docker compose ps egress-proxy --format '{{.Status}}' 2>/dev/null | grep -q 'Up'; then
    echo "Starting egress proxy..."
    docker compose up -d egress-proxy
    sleep 3
fi

echo "🔐 Launching Crypto Vault (X11 mode)..."
echo "   Chrome will open directly on your desktop."
echo ""

docker run --rm -it \
    --name crypto-vault-x11 \
    --network crypto-safe-container_vault-internal \
    --ip 172.30.0.10 \
    --dns 172.30.0.2 \
    -e DISPLAY="${DISPLAY:-:0}" \
    -e PROXY_SERVER="http://172.30.0.2:3128" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v crypto-vault-chrome:/home/kasm-user/.config/google-chrome \
    -v crypto-vault-downloads:/home/kasm-user/Downloads \
    -v crypto-vault-projects:/home/kasm-user/projects \
    --shm-size=512m \
    --cap-drop ALL \
    --security-opt no-new-privileges:true \
    --entrypoint bash \
    crypto-safe-container-crypto-vault \
    -c '
        # Run Chrome with proxy and wallet extensions welcome page
        exec /opt/google/chrome/google-chrome \
            --no-sandbox \
            --password-store=basic \
            --proxy-server=http://172.30.0.2:3128 \
            --no-first-run \
            --disable-search-engine-choice-screen \
            file:///opt/chrome-extensions/welcome.html \
            "$@"
    '
