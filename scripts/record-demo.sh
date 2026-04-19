#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# Record `.github/demo.gif` — full 8-10s demo showing:
#   1. ./vault-x11.sh launching Chrome
#   2. Welcome page visible
#   3. Proxy blocking evil.com
#   4. Proxy allowing api.etherscan.io
#
# Requires: ffmpeg, vhs (for the terminal half)
#   Debian/Ubuntu: sudo apt install ffmpeg
#   vhs:           go install github.com/charmbracelet/vhs@latest
#                  or: brew install vhs  (macOS)
#
# Run from the project root:
#   ./scripts/record-demo.sh
# ─────────────────────────────────────────────────

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT=".github/demo.gif"
RAW="/tmp/crypto-vault-demo.mp4"
DURATION=10            # seconds
FPS=15
WIDTH=1280             # output width; height auto
REGION="1280x720+0+0"  # x11grab region; adjust to your screen

command -v ffmpeg >/dev/null || { echo "ffmpeg required: sudo apt install ffmpeg"; exit 1; }
command -v vhs    >/dev/null || { echo "vhs required:    go install github.com/charmbracelet/vhs@latest"; exit 1; }

echo "1) Rendering terminal half (vhs)..."
vhs scripts/demo.tape

echo
echo "2) About to screen-record ${DURATION}s at ${REGION}."
echo "   Position Chrome + a terminal in the top-left ${REGION%+*}."
echo "   During recording, run: ./vault-x11.sh  (then run the terminal commands shown)"
read -p "Ready? [Enter to start, Ctrl-C to cancel] " _

ffmpeg -y -video_size "${REGION%+*}" -framerate "$FPS" -f x11grab \
    -i "${DISPLAY:-:0}+${REGION#*+}" -t "$DURATION" \
    -vf "scale=${WIDTH}:-1:flags=lanczos" "$RAW"

echo
echo "3) Converting to GIF (palette for size)..."
PAL=/tmp/crypto-vault-palette.png
ffmpeg -y -i "$RAW" -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,palettegen" "$PAL"
ffmpeg -y -i "$RAW" -i "$PAL" -filter_complex \
    "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos[x];[x][1:v]paletteuse" "$OUT"

rm -f "$RAW" "$PAL"
echo
echo "  Done: $OUT ($(du -h "$OUT" | cut -f1))"
echo "  If the file is over 2MB, lower FPS or WIDTH at the top of this script."
