#!/bin/bash
# Receives a screenshot from Mac and loads it into X11 clipboard for Claude Code
# Usage: called via SSH from Mac daemon, or manually: ./receive.sh /path/to/image.png

set -euo pipefail

DISPLAY=:99
export DISPLAY

SCREENSHOTS_DIR="$HOME/screenshots"
mkdir -p "$SCREENSHOTS_DIR"

IMAGE_PATH="${1:-}"

if [ -z "$IMAGE_PATH" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    IMAGE_PATH="$SCREENSHOTS_DIR/screenshot_${TIMESTAMP}.png"
    cat > "$IMAGE_PATH"
fi

if [ ! -f "$IMAGE_PATH" ] || [ ! -s "$IMAGE_PATH" ]; then
    echo "ERROR: No image data received" >&2
    exit 1
fi

xclip -selection clipboard -t image/png -i < "$IMAGE_PATH"
ln -sf "$IMAGE_PATH" "$SCREENSHOTS_DIR/latest.png"

echo "OK:$IMAGE_PATH"
