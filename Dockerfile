########################################################
# Crypto Vault — Chrome + Foundry + Node.js
#
# Base: kasmweb/chrome (Debian, Chromium)
# Adds: Foundry (forge/cast/anvil), Node.js 20, ethers.js,
#        hardhat, and wallet extension welcome page
# Run via: ./vault-x11.sh (native X11 window)
########################################################

FROM kasmweb/chrome:1.18.0

USER root

# ── Switch apt to HTTPS (port 80 may be blocked in some envs) ──
RUN sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g' /etc/apt/sources.list \
    && sed -i 's|http://security.ubuntu.com|https://security.ubuntu.com|g' /etc/apt/sources.list

# ── System deps ──
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl git ca-certificates gnupg build-essential python3 \
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

# ── Chrome managed policy ──
RUN mkdir -p /etc/opt/chrome/policies/managed \
    && rm -f /etc/opt/chrome/policies/managed/urlblocklist.json
COPY chrome-policies.json /etc/opt/chrome/policies/managed/policies.json

# ── Welcome page with wallet install links ──
COPY welcome.html /opt/chrome-extensions/welcome.html

# ── Hardened npm defaults ──
RUN echo "ignore-scripts=true" >> /etc/npmrc

# ── Pre-populate home dir from KasmVNC default profile ──
RUN cp -rp /home/kasm-default-profile/. /home/kasm-user/ \
    && mkdir -p /home/kasm-user/Uploads /home/kasm-user/Downloads \
                /home/kasm-user/Desktop /home/kasm-user/projects \
                /home/kasm-user/.config/google-chrome \
    && ln -sf /home/kasm-user/Uploads /home/kasm-user/Desktop/Uploads \
    && ln -sf /home/kasm-user/Downloads /home/kasm-user/Desktop/Downloads \
    && chown -R 1000:0 /home/kasm-user

USER 1000
WORKDIR /home/kasm-user/projects

# KasmVNC entrypoint is inherited from base image
