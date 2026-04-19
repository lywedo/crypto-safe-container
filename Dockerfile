########################################################
# Crypto Vault — Chrome + Foundry + Node.js
#
# Base: debian:bookworm-slim (minimal, ~80MB)
# Chrome is installed from Google's official apt repo.
# Adds: Foundry (forge/cast/anvil), Node.js 20, ethers.js,
#        hardhat, and wallet extension welcome page.
# Run via: ./vault-x11.sh (native X11 window)
########################################################

FROM debian:bookworm-slim

# ── System deps + Chromium ──
# Using Debian's chromium (not Google Chrome) because recent Chrome
# stable builds hit SIGILL on Hyper-V/WSL2 due to aggressive SIMD in
# the precompiled binaries. Debian's build is more conservative and
# runs everywhere. Wallet extensions (same IDs) work identically.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git gnupg build-essential python3 \
        chromium fonts-liberation libu2f-udev libasound2 xdg-utils \
    && ln -sf /usr/bin/chromium /usr/local/bin/google-chrome \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 20 LTS ──
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Foundry (forge, cast, anvil, chisel) ──
ENV FOUNDRY_DIR="/opt/foundry"
RUN curl -L https://foundry.paradigm.xyz | FOUNDRY_DIR=/opt/foundry bash \
    && /opt/foundry/bin/foundryup
ENV PATH="/opt/foundry/bin:${PATH}"
RUN forge --version && cast --version && anvil --version

# ── Global Node.js Web3 tools ──
RUN npm install -g \
        hardhat \
        ethers@6 \
        @nomicfoundation/hardhat-toolbox \
        solc \
    && npm cache clean --force

# ── Chromium managed policy (same file deployed to both Chromium and
#    Google Chrome policy paths for forward-compatibility) ──
RUN mkdir -p /etc/chromium/policies/managed /etc/opt/chrome/policies/managed
COPY chrome-policies.json /etc/chromium/policies/managed/policies.json
COPY chrome-policies.json /etc/opt/chrome/policies/managed/policies.json

# ── Welcome page with wallet install links ──
RUN mkdir -p /opt/chrome-extensions
COPY welcome.html /opt/chrome-extensions/welcome.html

# ── Hardened npm defaults ──
RUN echo "ignore-scripts=true" >> /etc/npmrc

# ── Non-root user ──
RUN useradd -m -u 1000 -U -s /bin/bash vault \
    && mkdir -p /home/vault/Downloads /home/vault/projects \
                /home/vault/.config/google-chrome \
    && chown -R 1000:1000 /home/vault

USER 1000
WORKDIR /home/vault/projects
