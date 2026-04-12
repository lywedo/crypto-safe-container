SHELL := /bin/bash
PROJECT_DIR := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)

.PHONY: install uninstall build

build:
	docker compose build

# Linux / WSL — adds "Crypto Vault" to app launcher / Start Menu
install-linux:
	@mkdir -p ~/.local/share/applications
	@sed 's|Exec=.*|Exec=$(PROJECT_DIR)/vault-x11.sh|' \
		$(PROJECT_DIR)/crypto-vault.desktop \
		> ~/.local/share/applications/crypto-vault.desktop
	@chmod +x ~/.local/share/applications/crypto-vault.desktop
	@echo "Installed — search 'Crypto Vault' in your app launcher."

# macOS — creates Crypto Vault.app in /Applications
install-mac:
	@mkdir -p "/Applications/Crypto Vault.app/Contents/MacOS"
	@printf '#!/bin/bash\nexec "$(PROJECT_DIR)/vault-x11.sh"\n' \
		> "/Applications/Crypto Vault.app/Contents/MacOS/Crypto Vault"
	@chmod +x "/Applications/Crypto Vault.app/Contents/MacOS/Crypto Vault"
	@defaults write "$(PROJECT_DIR)/Info" CFBundleName "Crypto Vault"
	@cp -f "$(PROJECT_DIR)/Info.plist" "/Applications/Crypto Vault.app/Contents/Info.plist" 2>/dev/null || \
		printf '<?xml version="1.0"?>\n<plist version="1.0"><dict>\n<key>CFBundleName</key><string>Crypto Vault</string>\n<key>CFBundleExecutable</key><string>Crypto Vault</string>\n<key>CFBundleIdentifier</key><string>com.crypto-vault</string>\n<key>CFBundleVersion</key><string>1.0</string>\n</dict></plist>\n' \
		> "/Applications/Crypto Vault.app/Contents/Info.plist"
	@echo "Installed — find 'Crypto Vault' in Launchpad / Applications."

uninstall:
	rm -f ~/.local/share/applications/crypto-vault.desktop
	rm -rf "/Applications/Crypto Vault.app"
	@echo "Removed."
