#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# Crypto Vault — Proxy Smoke Test
#
# Verifies three invariants:
#   1. Whitelisted domains reachable through the proxy
#   2. Non-whitelisted domains blocked by the proxy (403)
#   3. Direct internet unreachable from vault-internal network
#
# Usage: ./scripts/smoketest.sh
# Used by: .github/workflows/ci.yml (same assertions)
# ─────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

PROXY="http://172.30.0.2:3128"
NET="vault-internal"
IMAGE="curlimages/curl:latest"

pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; exit 1; }

# Run curl inside an alpine-curl container on vault-internal
proxy_curl() {
    docker run --rm --network "$NET" --dns 172.30.0.2 "$IMAGE" "$@"
}

echo "Starting egress-proxy..."
docker compose up -d egress-proxy

echo "Waiting for egress-proxy to become healthy..."
for i in $(seq 1 30); do
    status=$(docker inspect vault-egress-proxy --format '{{.State.Health.Status}}' 2>/dev/null || echo starting)
    [ "$status" = "healthy" ] && break
    sleep 2
done
[ "$status" = "healthy" ] || fail "egress-proxy did not become healthy (status: $status)"
echo "  proxy: $status"
echo

echo "1. Whitelisted domain (api.etherscan.io) through proxy..."
code=$(proxy_curl -s -o /dev/null -w "%{http_code}" -x "$PROXY" --max-time 15 \
    "https://api.etherscan.io/api" || echo "000")
[ "$code" = "200" ] || fail "expected 200, got $code"
pass "whitelisted → 200"
echo

echo "2. Non-whitelisted domain (evil.com) through proxy..."
# For HTTPS through an HTTP proxy, Squid denies at CONNECT (403).
# %{http_connect} may concatenate codes from multi-attempt connects (e.g. "403000");
# we only care that a 403 appears.
code=$(proxy_curl -s -o /dev/null -w "%{http_connect}" -x "$PROXY" --max-time 10 \
    "https://evil.com" 2>/dev/null || echo "000")
case "$code" in
    403*) pass "non-whitelisted → 403 from Squid" ;;
    *)    fail "expected CONNECT 403, got $code" ;;
esac
echo

echo "3. Direct internet (google.com) bypassing proxy..."
if proxy_curl -sf --max-time 3 "https://google.com" -o /dev/null 2>/dev/null; then
    fail "direct internet reachable — vault-internal network is not isolated!"
fi
pass "direct → timeout/failure (network isolated)"
echo

echo "All 3 proxy invariants hold."
