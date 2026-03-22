#!/bin/bash
# Mac-side daemon: watches clipboard for new images and sends them to remote server
# Dependencies: brew install pngpaste
# Usage: ./clipboard-sync.sh

# Homebrew PATH (LaunchAgent doesn't inherit shell PATH)
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH:-/usr/bin:/bin}"

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: config.sh not found. Run: bash install.sh"
    exit 1
fi

source "$CONFIG_FILE"

TEMP_FILE="/tmp/.clipboard-sync-latest.png"
LAST_CHANGE_COUNT=""
LAST_IMAGE_HASH=""

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

get_clipboard_change_count() {
    osascript -e 'use framework "AppKit"
return (current application'\''s NSPasteboard'\''s generalPasteboard()'\''s changeCount()) as integer' 2>/dev/null
}

if ! command -v pngpaste &>/dev/null; then
    echo "ERROR: pngpaste not found. Install: brew install pngpaste"
    exit 1
fi

log "Clipboard sync started (host: $SSH_HOST, interval: ${POLL_INTERVAL}s)"
log "Waiting for images in clipboard..."

# Initialize with current change count to skip whatever is already in clipboard
LAST_CHANGE_COUNT=$(get_clipboard_change_count)

while true; do
    CURRENT_CHANGE_COUNT=$(get_clipboard_change_count)
    if [ "$CURRENT_CHANGE_COUNT" != "$LAST_CHANGE_COUNT" ]; then
        if pngpaste "$TEMP_FILE" 2>/dev/null; then
            CURRENT_IMAGE_HASH=$(md5 -q "$TEMP_FILE")
            if [ "$CURRENT_IMAGE_HASH" != "$LAST_IMAGE_HASH" ]; then
                log "New image detected (clipboard change: $CURRENT_CHANGE_COUNT)"
                RESULT=$(cat "$TEMP_FILE" | ssh "$SSH_HOST" "$REMOTE_RECEIVE" 2>&1)
                if [[ "$RESULT" == OK:* ]]; then
                    LAST_IMAGE_HASH="$CURRENT_IMAGE_HASH"
                    LAST_CHANGE_COUNT="$CURRENT_CHANGE_COUNT"
                    REMOTE_PATH="${RESULT#OK:}"
                    log "Synced: $REMOTE_PATH"
                    osascript -e "display notification \"Screenshot synced\" with title \"Screenshoter\"" 2>/dev/null
                else
                    log "ERROR: sync failed: $RESULT"
                fi
            else
                LAST_CHANGE_COUNT="$CURRENT_CHANGE_COUNT"
                log "Skipped duplicate image (clipboard change: $CURRENT_CHANGE_COUNT)"
            fi
        else
            # Clipboard changed but doesn't contain an image — update count to skip it
            LAST_CHANGE_COUNT="$CURRENT_CHANGE_COUNT"
        fi
    fi
    sleep "$POLL_INTERVAL"
done
