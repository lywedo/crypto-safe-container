# Security Policy

## Reporting a Vulnerability

If you find a security vulnerability in crypto-safe-container, **please do NOT open a public issue**.

Instead, use one of these methods:

1. **GitHub Private Vulnerability Reporting:**
   https://github.com/lywedo/crypto-safe-container/security/advisories/new

2. **Email:** lywedo@gmail.com

We'll acknowledge receipt within 48 hours and aim to release a fix within 7 days for critical issues.

## Scope

This project is a Docker-based isolation tool, not a wallet or smart contract. Relevant vulnerabilities include:

- Container escape vectors
- Proxy bypass techniques
- Whitelist circumvention
- Credential exposure in images or configs
- Privilege escalation within the container

## Known Limitations

These are **by design** and not considered vulnerabilities:

- Docker containers share the host kernel (use a VM for stronger isolation)
- The Squid proxy trusts DNS resolution
- USB passthrough for hardware wallets requires `--device` which relaxes isolation
- Chrome runs with `--no-sandbox` inside the container — acceptable because the container itself provides isolation via `--cap-drop ALL` and `no-new-privileges`, but users should be aware that browser sandboxing is relaxed
