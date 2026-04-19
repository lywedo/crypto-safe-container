#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# Crypto Vault — Helper Commands
# Thin wrapper around docker compose (profile: vault).
# Each dev command spins up an ephemeral vault container.
# ─────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
CMD="${1:-help}"

# Run a one-shot command inside a fresh vault container
vault_run() {
    docker compose --profile vault run --rm crypto-vault "$@"
}

case "$CMD" in
  up)
    echo "Launching Crypto Vault..."
    "$SCRIPT_DIR/vault-x11.sh"
    ;;

  down)
    echo "Stopping Crypto Vault..."
    docker compose --profile vault down
    ;;

  shell)
    vault_run bash
    ;;

  forge)
    shift
    vault_run forge "$@"
    ;;

  cast)
    shift
    vault_run cast "$@"
    ;;

  hardhat)
    shift
    vault_run npx hardhat "$@"
    ;;

  logs)
    docker compose logs -f "${2:-egress-proxy}"
    ;;

  whitelist)
    echo "Current whitelist:"
    grep -v "^#" squid/whitelist.txt | grep -v "^$"
    echo
    echo "Edit squid/whitelist.txt then run: $0 reload-proxy"
    ;;

  reload-proxy)
    docker compose restart egress-proxy
    echo "Proxy restarted with updated whitelist."
    ;;

  backup)
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo "Backing up Chrome profile..."
    docker run --rm \
      -v crypto-vault-chrome:/data:ro \
      -v "$(pwd)/$BACKUP_DIR":/backup \
      alpine tar czf /backup/chrome-profile.tar.gz -C /data .
    echo "Backup saved to $BACKUP_DIR/chrome-profile.tar.gz"
    echo "Store this backup ENCRYPTED and OFFLINE."
    ;;

  nuke)
    echo "This will DELETE all vault data (wallets, browser profile, projects)."
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      docker compose --profile vault down -v
      echo "All vault data destroyed."
    else
      echo "Cancelled."
    fi
    ;;

  smoketest)
    ./scripts/smoketest.sh
    ;;

  status)
    docker compose --profile vault ps
    ;;

  help|*)
    cat <<EOF
Crypto Vault — Helper Commands

  ./vault.sh up            Launch Chrome (X11)
  ./vault.sh down          Stop everything
  ./vault.sh shell         Open bash in an ephemeral vault container
  ./vault.sh forge <args>  Run forge commands
  ./vault.sh cast <args>   Run cast commands
  ./vault.sh hardhat <a>   Run hardhat commands
  ./vault.sh logs [svc]    Follow container logs
  ./vault.sh whitelist     Show allowed domains
  ./vault.sh reload-proxy  Apply whitelist changes
  ./vault.sh smoketest     Verify proxy invariants
  ./vault.sh backup        Backup Chrome profile
  ./vault.sh status        List services + profile containers
  ./vault.sh nuke          DELETE all vault data
EOF
    ;;
esac
