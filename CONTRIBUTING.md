# Contributing to crypto-safe-container

Thanks for your interest in making crypto safer for developers! Here's how to contribute.

## Ways to Contribute

### 🌐 Whitelist Additions
The easiest and most impactful contribution. If you use a DeFi protocol that isn't in `squid/whitelist.txt`:

1. Add the domain(s) to `squid/whitelist.txt` under the appropriate section
2. Include only the minimum domains needed (check browser DevTools → Network tab)
3. Use `.domain.com` format to allow subdomains
4. Submit a PR with the protocol name and a link to verify it's legitimate

### 🔒 Security Improvements
- Tighter seccomp profiles
- AppArmor/SELinux policies
- Better network isolation techniques
- Vulnerability reports (see [Security Policy](#security))

### 📖 Documentation
- Setup guides for specific distros/environments
- Video demos and tutorials
- Translations

### 🐛 Bug Reports
Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).

## Development Setup

```bash
git clone https://github.com/lywedo/crypto-safe-container.git
cd crypto-safe-container
cp .env.example .env
./vault.sh up
```

## Pull Request Process

1. Fork the repo and create your branch from `main`
2. Test your changes locally with `./vault.sh up` and `./vault.sh status`
3. Update documentation if you changed behavior
4. Ensure CI passes (the workflow builds the image and runs proxy tests)
5. Write a clear PR description explaining *why*, not just *what*

## Code Style

- Shell scripts: Use `shellcheck` — no warnings
- YAML: 2-space indent
- Dockerfiles: One `RUN` per logical step, clean up apt caches

## Security

If you find a security vulnerability, **please do NOT open a public issue**. Instead, email the maintainer or use GitHub's [private vulnerability reporting](https://github.com/lywedo/crypto-safe-container/security/advisories/new).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
