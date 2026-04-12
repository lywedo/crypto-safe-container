<h1 align="center">🔐 crypto-safe-container</h1>

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
  <a href="https://hub.docker.com/r/kasmweb/chrome">
    <img src="https://img.shields.io/badge/base-kasmweb%2Fchrome-blue" alt="Base Image" />
  </a>
</p>

<p align="center">
  <a href="#-why-this-exists">Why</a> •
  <a href="#%EF%B8%8F-architecture">Architecture</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-cli-tools">CLI Tools</a> •
  <a href="#-hardware-wallets">Hardware Wallets</a> •
  <a href="#-wsl2-users">WSL2</a> •
  <a href="#-faq">FAQ</a>
</p>

---

## 🚨 Why This Exists

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

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Your Host Machine                      │
│                                                           │
│    Browser → https://localhost:6901 (KasmVNC)            │
│                       │                                   │
│    ┌──────────────────┼───────── vault-internal ───────┐  │
│    │                  │          (no internet)          │  │
│    │   ┌──────────────▼────────────────────────────┐   │  │
│    │   │        crypto-vault (172.30.0.10)          │   │  │
│    │   │                                            │   │  │
│    │   │   🌐 Chromium (KasmVNC)                    │   │  │
│    │   │   🦊 MetaMask  👻 Phantom  🐰 Rabby       │   │  │
│    │   │   🔨 Foundry (forge / cast / anvil)        │   │  │
│    │   │   📦 Node.js 20 + Hardhat + ethers.js      │   │  │
│    │   │                                            │   │  │
│    │   │   🔒 --cap-drop ALL                        │   │  │
│    │   │   🔒 read-only filesystem                  │   │  │
│    │   │   🔒 no-new-privileges                     │   │  │
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

- 🔐 **No direct internet** — The vault sits on an `internal: true` Docker network
- 🚧 **Whitelist-only egress** — All traffic passes through a Squid proxy; only domains in `whitelist.txt` are allowed
- 🖥️ **Display isolation** — KasmVNC (not X11) means no keylogging, no clipboard leaks to host
- 🛡️ **Hardened container** — All Linux capabilities dropped, read-only root FS, PID limits, memory caps
- 📦 **npm locked down** — `ignore-scripts=true` globally prevents postinstall attacks inside the vault
- 🔌 **Hardware wallet ready** — USB passthrough for Ledger/Trezor (keys never touch software)

---

## 🚀 Quick Start

**Prerequisites:** Docker Engine 20.10+ and Docker Compose v2

```bash
git clone https://github.com/lywedo/crypto-safe-container.git
cd crypto-safe-container

# Set your VNC password
cp .env.example .env
nano .env    # Change VAULT_PASSWORD

# Build and start
chmod +x vault.sh
./vault.sh up
```

Open **https://localhost:6901** in your browser, accept the self-signed cert, and enter your VNC password.

MetaMask, Phantom, and Rabby are pre-installed automatically on first launch.

---

## 🔧 CLI Tools

Web3 CLI tools are available inside the vault and via the helper script:

```bash
# Open a shell inside the vault
./vault.sh shell

# Foundry commands (from host)
./vault.sh forge init my-project
./vault.sh forge build
./vault.sh forge test
./vault.sh cast balance vitalik.eth --rpc-url https://eth.llamarpc.com
./vault.sh cast chain-id --rpc-url https://eth.llamarpc.com

# Hardhat (from host)
./vault.sh hardhat compile

# Or work interactively inside the vault
./vault.sh shell
cd projects && npx hardhat init
```

### All `vault.sh` Commands

| Command | Description |
|---|---|
| `./vault.sh up` | Build and start vault + proxy |
| `./vault.sh down` | Stop everything |
| `./vault.sh shell` | Bash shell inside the vault |
| `./vault.sh forge <args>` | Run Foundry forge |
| `./vault.sh cast <args>` | Run Foundry cast |
| `./vault.sh hardhat <args>` | Run Hardhat |
| `./vault.sh logs [service]` | Follow container logs |
| `./vault.sh whitelist` | Show allowed domains |
| `./vault.sh reload-proxy` | Apply whitelist changes |
| `./vault.sh backup` | Backup Chrome profile |
| `./vault.sh status` | Health check + proxy test |
| `./vault.sh nuke` | ⚠️ Delete ALL vault data |

---

## 🌐 Managing the Whitelist

The proxy blocks everything not in `squid/whitelist.txt`. To add a new protocol:

```bash
# Add a domain
echo ".newprotocol.xyz" >> squid/whitelist.txt

# Apply without restarting the vault
./vault.sh reload-proxy

# Verify
./vault.sh status
```

Default whitelist includes: Ethereum/Solana RPCs, major DeFi (Uniswap, Aave, Jupiter, Raydium), block explorers, wallet update servers, IPFS gateways, and hardware wallet bridges. See [`squid/whitelist.txt`](squid/whitelist.txt) for the full list.

---

## 🔌 Hardware Wallets

Ledger and Trezor work via USB passthrough. Your private keys stay on the device's secure element — they never touch the container.

**Step 1: Install udev rules on your host** (Linux / WSL2)

```bash
# Ledger
wget -q -O - https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh | sudo bash

# Trezor
sudo curl https://data.trezor.io/udev/51-trezor.rules -o /etc/udev/rules.d/51-trezor.rules
sudo udevadm control --reload-rules
```

**Step 2: Uncomment in `docker-compose.yml`**

```yaml
devices:
  - /dev/bus/usb:/dev/bus/usb
  - /dev/hidraw0:/dev/hidraw0
group_add:
  - plugdev
```

**Step 3:** `./vault.sh down && ./vault.sh up`

---

## 🪟 WSL2 Users

This works on WSL2 with some caveats:

- ✅ **Use the VNC web client** (https://localhost:6901) — not X11 forwarding
- ⚠️ WSL2 filesystem is readable from Windows at `\\wsl$\` — Docker volumes (where your wallet data lives) are inside Docker's VM and safer, but be aware
- 🔒 Consider Docker Desktop's **Hyper-V backend** for stronger isolation
- 🔒 Disable Windows/WSL interop if you want maximum separation:

```ini
# /etc/wsl.conf
[interop]
enabled=false

[automount]
enabled=false
```

---

## 💾 Backup & Recovery

```bash
# Backup Chrome profile (encrypted wallet vaults, extension config)
./vault.sh backup
# → backups/YYYYMMDD_HHMMSS/chrome-profile.tar.gz

# Encrypt before storing
gpg -c backups/*/chrome-profile.tar.gz
```

> **Your seed phrase is the real backup.** The Chrome profile backup is a convenience — it preserves wallet settings, token lists, and approvals. If you have your seed phrases stored safely offline (metal/paper, never digital), you can always restore from scratch.

---

## ⚠️ Threat Model & Limitations

Be honest about what this does and doesn't protect:

| Protected | NOT Protected |
|---|---|
| ✅ Wallet extensions isolated from host filesystem | ❌ Docker shares the host kernel — container escapes exist |
| ✅ Exfiltration blocked to non-whitelisted domains | ❌ DNS poisoning could theoretically bypass the whitelist |
| ✅ Display isolated (no X11 keylogging) | ❌ Browser zero-days can still compromise the vault |
| ✅ npm postinstall disabled globally | ❌ Your seed phrase — store it offline, never digitally |

**For wallets holding >$50K:** Consider a dedicated VM (VirtualBox/KVM) or Qubes OS instead of Docker. Container isolation is meaningful but not equivalent to hardware virtualization.

**A hardware wallet remains the single strongest protection** because private keys never exist in software, regardless of how compromised the host is.

---

## 📁 File Structure

```
crypto-safe-container/
├── docker-compose.yml          # Vault + egress proxy services
├── Dockerfile                  # Custom image (Kasm Chrome + Foundry + Node.js)
├── chrome-policies.json        # Auto-install MetaMask, Phantom, Rabby
├── vault.sh                    # Helper CLI
├── .env.example                # VNC password template
├── .dockerignore
├── .gitignore
├── LICENSE
├── CONTRIBUTING.md
├── squid/
│   ├── squid.conf              # Proxy configuration
│   └── whitelist.txt           # Allowed domains (edit this!)
└── .github/
    ├── workflows/
    │   └── ci.yml              # Build + security scan
    └── ISSUE_TEMPLATE/
        ├── bug_report.md
        ├── feature_request.md
        └── domain_request.md
```

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

The most impactful contributions right now:
- **Whitelist additions** for popular DeFi protocols
- **Security hardening** improvements
- **Testing** on different Docker/OS versions
- **Documentation** — especially video demos

---

## 📜 License

[MIT](LICENSE) — use it, fork it, protect your crypto.

---

<p align="center">
  <strong>If this project helped you, consider giving it a ⭐</strong><br />
  Every star helps more developers discover it before they get scammed.
</p>
