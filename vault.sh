#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# Crypto Vault — Helper Commands
# ─────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CMD="${1:-help}"

case "$CMD" in
  up)
    echo "🔐 Starting Crypto Vault..."
    docker compose up -d egress-proxy
    sleep 2
    "$SCRIPT_DIR/vault-x11.sh"
    ;;

  down)
    echo "🛑 Stopping Crypto Vault..."
    docker stop crypto-vault-x11 2>/dev/null || true
    docker compose down
    ;;

  shell)
    echo "🐚 Entering vault shell..."
    docker exec -it crypto-vault-x11 /bin/bash
    ;;

  forge)
    shift
    docker exec -it crypto-vault-x11 forge "$@"
    ;;

  cast)
    shift
    docker exec -it crypto-vault-x11 cast "$@"
    ;;

  hardhat)
    shift
    docker exec -it -w /home/kasm-user/projects crypto-vault-x11 npx hardhat "$@"
    ;;

  logs)
    docker compose logs -f "${2:-egress-proxy}"
    ;;

  whitelist)
    echo "📝 Current whitelist:"
    cat squid/whitelist.txt | grep -v "^#" | grep -v "^$"
    echo ""
    echo "Edit squid/whitelist.txt then run: $0 reload-proxy"
    ;;

  reload-proxy)
    echo "🔄 Reloading proxy whitelist..."
    docker compose restart egress-proxy
    echo "✅ Proxy restarted with updated whitelist."
    ;;

  backup)
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo "💾 Backing up Chrome profile (includes wallet data)..."
    docker run --rm \
      -v crypto-vault-chrome:/data:ro \
      -v "$(pwd)/$BACKUP_DIR":/backup \
      alpine tar czf /backup/chrome-profile.tar.gz -C /data .
    echo "✅ Backup saved to $BACKUP_DIR/chrome-profile.tar.gz"
    echo "⚠️  Store this backup ENCRYPTED and OFFLINE."
    ;;

  nuke)
    echo "💣 This will DELETE all vault data (wallets, browser profile, projects)."
    read -p "   Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      docker stop crypto-vault-x11 2>/dev/null || true
      docker compose down -v
      echo "✅ All vault data destroyed."
    else
      echo "❌ Cancelled."
    fi
    ;;

  status)
    echo "📊 Vault Status:"
    docker compose ps
    docker ps --filter name=crypto-vault-x11 --format "{{.Names}} {{.Status}}" 2>/dev/null
    ;;

  help|*)
    echo "Crypto Vault — Helper Commands"
    echo ""
    echo "  ./vault.sh up            Launch Chrome + proxy (X11)"
    echo "  ./vault.sh down          Stop everything"
    echo "  ./vault.sh shell         Open bash inside vault"
    echo "  ./vault.sh forge <args>  Run forge commands"
    echo "  ./vault.sh cast <args>   Run cast commands"
    echo "  ./vault.sh hardhat <a>   Run hardhat commands"
    echo "  ./vault.sh logs [svc]    Follow container logs"
    echo "  ./vault.sh whitelist     Show allowed domains"
    echo "  ./vault.sh reload-proxy  Apply whitelist changes"
    echo "  ./vault.sh backup        Backup Chrome profile"
    echo "  ./vault.sh status        Health check"
    echo "  ./vault.sh nuke          DELETE all vault data"
    ;;
esac
