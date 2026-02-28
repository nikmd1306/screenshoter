#!/bin/bash
# Mac-side daemon: watches clipboard for new images and sends them to remote server
# Dependencies: brew install pngpaste
# Usage: ./clipboard-sync.sh

# Homebrew PATH (LaunchAgent doesn't inherit shell PATH)
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH:-/usr/bin:/bin}"

set -uo pipefail

#############################
# CONFIGURATION - EDIT THIS #
#############################
SSH_HOST="dev"                          # SSH host from ~/.ssh/config (or user@host)
REMOTE_RECEIVE="~/screenshoter/server/receive.sh"  # Path to receive.sh on server
POLL_INTERVAL=1                         # Seconds between clipboard checks
#############################

TEMP_FILE="/tmp/.clipboard-sync-latest.png"
LAST_HASH=""

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

if ! command -v pngpaste &>/dev/null; then
    echo "ERROR: pngpaste not found. Install: brew install pngpaste"
    exit 1
fi

log "Clipboard sync started (host: $SSH_HOST, interval: ${POLL_INTERVAL}s)"
log "Waiting for images in clipboard..."

while true; do
    if pngpaste "$TEMP_FILE" 2>/dev/null; then
        CURRENT_HASH=$(md5 -q "$TEMP_FILE")
        if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
            log "New image detected (hash: ${CURRENT_HASH:0:8}...)"
            RESULT=$(cat "$TEMP_FILE" | ssh "$SSH_HOST" "$REMOTE_RECEIVE" 2>&1)
            if [[ "$RESULT" == OK:* ]]; then
                LAST_HASH="$CURRENT_HASH"
                REMOTE_PATH="${RESULT#OK:}"
                log "Synced: $REMOTE_PATH"
                osascript -e "display notification \"Screenshot synced\" with title \"Screenshoter\"" 2>/dev/null
            else
                log "ERROR: sync failed: $RESULT"
            fi
        fi
    fi
    sleep "$POLL_INTERVAL"
done
