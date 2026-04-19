# VHS tape for the terminal half of the demo GIF.
# Shows the proxy rejecting evil.com and allowing api.etherscan.io.
#
# Render:  vhs scripts/demo.tape
# Output:  scripts/demo-terminal.gif
#
# Requires vhs (https://github.com/charmbracelet/vhs):
#   Go:     go install github.com/charmbracelet/vhs@latest
#   macOS:  brew install vhs

Output scripts/demo-terminal.gif

Set FontSize 16
Set Width 920
Set Height 300
Set Theme "Monokai Pro"
Set PlaybackSpeed 0.8

# Spin up an ephemeral vault shell
Type "docker compose --profile vault run --rm crypto-vault bash"
Enter
Sleep 2s

# 1. evil.com — should be denied by Squid
Type "# Non-whitelisted domain should be blocked..."
Enter
Sleep 500ms
Type "curl -sI --proxy http://172.30.0.2:3128 https://evil.com | head -3"
Enter
Sleep 3s

# 2. api.etherscan.io — should pass through
Type "# Whitelisted DeFi API should succeed..."
Enter
Sleep 500ms
Type "curl -sI --proxy http://172.30.0.2:3128 https://api.etherscan.io/api | head -3"
Enter
Sleep 2s

Type "exit"
Enter
Sleep 500ms
