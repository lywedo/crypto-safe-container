<h1 align="center">crypto-safe-container</h1>

<p align="center">
  <strong>A hardened Docker environment that isolates your crypto wallets behind a whitelist-only egress proxy.</strong><br />
  Run MetaMask, Rabby &amp; Phantom in a locked-down browser — even if it's compromised, stolen data can't phone home.
</p>

<p align="center">
  <a href="https://github.com/lywedo/crypto-safe-container/actions/workflows/ci.yml">
    <img src="https://github.com/lywedo/crypto-safe-container/actions/workflows/ci.yml/badge.svg" alt="CI" />
  </a>
  <a href="https://github.com/lywedo/crypto-safe-container/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/lywedo/crypto-safe-container" alt="License" />
  </a>
  <a href="https://github.com/lywedo/crypto-safe-container/stargazers">
    <img src="https://img.shields.io/github/stars/lywedo/crypto-safe-container?style=social" alt="Stars" />
  </a>
</p>

<p align="center">
  <a href="#-why-this-exists">Why</a> &bull;
  <a href="#%EF%B8%8F-architecture">Architecture</a> &bull;
  <a href="#-quick-start">Quick Start</a> &bull;
  <a href="#-cli-tools">CLI Tools</a> &bull;
  <a href="#-hardware-wallets">Hardware Wallets</a> &bull;
  <a href="#-faq">FAQ</a>
</p>

---

## Why This Exists

North Korean state hackers (Lazarus Group) run a campaign called **"Contagious Interview"** — they pose as recruiters, send developers a JS repo to clone, and `npm install` triggers obfuscated malware that drains every crypto wallet on your machine.

This isn't theoretical. It's industrial-scale:

| Stat | Source |
|---|---|
| **535+** malicious npm packages published | [Socket.dev (2025)](https://socket.dev/blog/north-korea-contagious-interview-campaign-338-malicious-npm-packages) |
| **$1.5B** stolen in a single hack (Bybit, Feb 2025) | [CSIS](https://www.csis.org/analysis/bybit-heist-and-future-us-crypto-regulation) |
| **16+** wallet extensions targeted (MetaMask, Phantom, etc.) | [Unit 42](https://unit42.paloaltonetworks.com/north-korean-threat-actors-lure-tech-job-seekers-as-fake-recruiters/) |
| Malware **rewrites MetaMask** to capture passwords on every unlock | [Seongsu Park (Feb 2026)](https://sp4rk.medium.com/) |
| VS Code `tasks.json` auto-executes malware on **folder open** | [The Hacker News (Mar 2026)](https://thehackernews.com/2026/03/north-korean-hackers-abuse-vs-code-auto.html) |

The attack works because `npm install` runs `postinstall` scripts that can do *anything* — read your filesystem, steal browser extension data, exfiltrate keys. If your wallets live on the same machine where you run untrusted code, they're one `npm install` away from being emptied.

**crypto-safe-container** solves this by running your wallets in an isolated Docker environment where even a compromised browser can only talk to domains you've explicitly approved.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Your Host Machine                      │
│                                                           │
│    X11 ─────── Chrome window (native, pixel-perfect)     │
│                       │                                   │
│    ┌──────────────────┼───────── vault-internal ───────┐  │
│    │                  │          (no internet)          │  │
│    │   ┌──────────────▼────────────────────────────┐   │  │
│    │   │        crypto-vault (172.30.0.10)          │   │  │
│    │   │                                            │   │  │
│    │   │   Chrome (X11 forwarding to host)          │   │  │
│    │   │   MetaMask / Phantom / Rabby               │   │  │
│    │   │   Foundry (forge / cast / anvil)            │   │  │
│    │   │   Node.js 20 + Hardhat + ethers.js          │   │  │
│    │   │                                            │   │  │
│    │   │   --cap-drop ALL                           │   │  │
│    │   │   no-new-privileges                        │   │  │
│    │   └──────────────┬────────────────────────────┘   │  │
│    │                  │ http://172.30.0.2:3128          │  │
│    │   ┌──────────────▼────────────────────────────┐   │  │
│    │   │      egress-proxy (172.30.0.2)             │   │  │
│    │   │      Squid → whitelist.txt ONLY            │───┼──┼──→ Internet
│    │   └───────────────────────────────────────────┘   │  │
│    └───────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**Key security properties:**

- **No direct internet** — The vault sits on an `internal: true` Docker network
- **Whitelist-only egress** — All traffic passes through a Squid proxy; only domains in `whitelist.txt` are allowed
- **Native X11 rendering** — Chrome runs as a native window via X11 forwarding — no VNC blur, no compression, no latency
- **Hardened container** — All Linux capabilities dropped, PID limits, memory caps, no-new-privileges
- **npm locked down** — `ignore-scripts=true` globally prevents postinstall attacks inside the vault
- **Hardware wallet ready** — USB passthrough for Ledger/Trezor (keys never touch software)

---

## Quick Start

**Prerequisites:** Docker Engine 20.10+ and Docker Compose v2

### Linux / WSL2

X11 works out of the box (WSLg on WSL2, native X server on Linux).

```bash
git clone https://github.com/lywedo/crypto-safe-container.git
cd crypto-safe-container

# Build the image
docker compose build

# Launch Chrome
./vault-x11.sh
```

Chrome opens as a native window with a welcome page to install MetaMask, Rabby, and Phantom from the Chrome Web Store. Extensions persist across restarts.

**Optional: Add to your app launcher / Start Menu**

```bash
make install-linux
# Search "Crypto Vault" in your app launcher
```

### macOS

Requires [XQuartz](https://www.xquartz.org/) for X11 support.

```bash
brew install --cask xquartz
# Log out and back in after installing XQuartz

git clone https://github.com/lywedo/crypto-safe-container.git
cd crypto-safe-container

docker compose build
./vault-x11.sh
```

**Optional: Add to Launchpad**

```bash
make install-mac
```

---

## Wallet Extensions

On first launch, Chrome opens a welcome page with install links for:

- **MetaMask** — Ethereum wallet & DApp browser
- **Rabby Wallet** — Multi-chain wallet with security alerts
- **Phantom** — Solana, Ethereum & multi-chain wallet

Click **"Add to Chrome"** for each one. This only needs to be done once — extensions are stored in a persistent Docker volume (`crypto-vault-chrome`) and survive container restarts.

---

## CLI Tools

Web3 CLI tools are available inside the vault and via the helper script:

```bash
# Open a shell inside the vault
./vault.sh shell

# Foundry commands (from host)
./vault.sh forge init my-project
./vault.sh forge build
./vault.sh forge test
./vault.sh cast balance vitalik.eth --rpc-url https://eth.llamarpc.com

# Hardhat (from host)
./vault.sh hardhat compile

# Or work interactively
./vault.sh shell
cd projects && npx hardhat init
```

### All `vault.sh` Commands

| Command | Description |
|---|---|
| `./vault.sh up` | Launch Chrome + proxy (X11) |
| `./vault.sh down` | Stop everything |
| `./vault.sh shell` | Bash shell inside the vault |
| `./vault.sh forge <args>` | Run Foundry forge |
| `./vault.sh cast <args>` | Run Foundry cast |
| `./vault.sh hardhat <args>` | Run Hardhat |
| `./vault.sh logs [service]` | Follow container logs |
| `./vault.sh whitelist` | Show allowed domains |
| `./vault.sh reload-proxy` | Apply whitelist changes |
| `./vault.sh backup` | Backup Chrome profile |
| `./vault.sh status` | Health check |
| `./vault.sh nuke` | Delete ALL vault data |

---

## Managing the Whitelist

The proxy blocks everything not in `squid/whitelist.txt`. To add a new protocol:

```bash
# Add a domain
echo ".newprotocol.xyz" >> squid/whitelist.txt

# Apply without restarting the vault
./vault.sh reload-proxy
```

Default whitelist includes: Ethereum/Solana RPCs, major DeFi (Uniswap, Aave, Jupiter, Raydium), block explorers, Chrome Web Store, wallet update servers, IPFS gateways, and hardware wallet bridges. See [`squid/whitelist.txt`](squid/whitelist.txt) for the full list.

---

## Hardware Wallets

Ledger and Trezor work via USB passthrough. Your private keys stay on the device's secure element — they never touch the container.

**Step 1: Install udev rules on your host** (Linux / WSL2)

```bash
# Ledger
wget -q -O - https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh | sudo bash

# Trezor
sudo curl https://data.trezor.io/udev/51-trezor.rules -o /etc/udev/rules.d/51-trezor.rules
sudo udevadm control --reload-rules
```

**Step 2: Uncomment USB passthrough in `vault-x11.sh`** (add these flags to the `docker run` command)

```bash
--device /dev/bus/usb:/dev/bus/usb \
--device /dev/hidraw0:/dev/hidraw0 \
--group-add plugdev
```

---

## Persistent Data

Three Docker volumes persist across container restarts:

| Volume | Contents |
|---|---|
| `crypto-vault-chrome` | Chrome profile — extensions, wallet data, bookmarks |
| `crypto-vault-downloads` | Downloaded files |
| `crypto-vault-projects` | Hardhat/Foundry project files |

Data survives `./vault.sh down` and restarts. Only `./vault.sh nuke` (which runs `docker compose down -v`) destroys it.

---

## Backup & Recovery

```bash
# Backup Chrome profile (encrypted wallet vaults, extension config)
./vault.sh backup
# -> backups/YYYYMMDD_HHMMSS/chrome-profile.tar.gz

# Encrypt before storing
gpg -c backups/*/chrome-profile.tar.gz
```

> **Your seed phrase is the real backup.** The Chrome profile backup is a convenience — it preserves wallet settings, token lists, and approvals. If you have your seed phrases stored safely offline (metal/paper, never digital), you can always restore from scratch.

---

## Threat Model & Limitations

Be honest about what this does and doesn't protect:

| Protected | NOT Protected |
|---|---|
| Wallet extensions isolated from host filesystem | Docker shares the host kernel — container escapes exist |
| Exfiltration blocked to non-whitelisted domains | DNS poisoning could theoretically bypass the whitelist |
| npm postinstall disabled globally | Browser zero-days can still compromise the vault |
| Chrome rendered natively (X11) — no VNC attack surface | Your seed phrase — store it offline, never digitally |

**For wallets holding >$50K:** Consider a dedicated VM (VirtualBox/KVM) or Qubes OS instead of Docker. Container isolation is meaningful but not equivalent to hardware virtualization.

**A hardware wallet remains the single strongest protection** because private keys never exist in software, regardless of how compromised the host is.

---

## File Structure

```
crypto-safe-container/
├── docker-compose.yml          # Egress proxy service
├── Dockerfile                  # Chrome + Foundry + Node.js image
├── vault-x11.sh                # Launch Chrome via X11 (main entry point)
├── vault.sh                    # Helper CLI commands
├── chrome-policies.json        # Chrome managed policy
├── welcome.html                # First-run wallet install page
├── Makefile                    # install-linux / install-mac targets
├── crypto-vault.desktop        # Linux .desktop entry
├── .env.example                # Template
├── .dockerignore
├── .gitignore
├── squid/
│   ├── squid.conf              # Proxy configuration
│   └── whitelist.txt           # Allowed domains (edit this!)
└── .github/
    ├── workflows/ci.yml
    └── ISSUE_TEMPLATE/
```

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

The most impactful contributions right now:
- **Whitelist additions** for popular DeFi protocols
- **Security hardening** improvements
- **Testing** on different Docker/OS versions
- **Documentation** — especially video demos

---

## License

[MIT](LICENSE) — use it, fork it, protect your crypto.

---

<p align="center">
  <strong>If this project helped you, consider giving it a star.</strong><br />
  Every star helps more developers discover it before they get scammed.
</p>
