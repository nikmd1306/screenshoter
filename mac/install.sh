#!/bin/bash
# Install script for Mac clipboard sync daemon
# Run this on your Mac: bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/clipboard-sync.sh"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
PLIST_SRC="$SCRIPT_DIR/com.screenshoter.clipboard-sync.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.screenshoter.clipboard-sync.plist"

echo "=== Screenshoter Mac Install ==="

# Check pngpaste
if ! command -v pngpaste &>/dev/null; then
    echo "Installing pngpaste..."
    brew install pngpaste
fi

# Make sync script executable
chmod +x "$SYNC_SCRIPT"

# Create config if not exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Config already exists: $CONFIG_FILE"
    source "$CONFIG_FILE"
    echo "  SSH_HOST=$SSH_HOST"
    echo "  REMOTE_RECEIVE=$REMOTE_RECEIVE"
    read -p "Reconfigure? [y/N]: " RECONF
    if [[ "$RECONF" != [yY] ]]; then
        SKIP_CONFIG=1
    fi
fi

if [ "${SKIP_CONFIG:-}" != "1" ]; then
    read -p "SSH host (from ~/.ssh/config or user@host) [dev]: " SSH_HOST
    SSH_HOST="${SSH_HOST:-dev}"

    read -p "Remote path to receive.sh [~/screenshoter/server/receive.sh]: " REMOTE_PATH
    REMOTE_PATH="${REMOTE_PATH:-~/screenshoter/server/receive.sh}"

    cat > "$CONFIG_FILE" <<EOF
SSH_HOST="$SSH_HOST"
REMOTE_RECEIVE="$REMOTE_PATH"
POLL_INTERVAL=1
EOF
    echo "Config saved: $CONFIG_FILE"
fi

# Test SSH connection
source "$CONFIG_FILE"
echo "Testing SSH connection to $SSH_HOST..."
if ssh "$SSH_HOST" "echo OK" 2>/dev/null | grep -q OK; then
    echo "SSH connection: OK"
else
    echo "WARNING: SSH connection failed. Check your SSH config."
fi

# Install LaunchAgent
echo "Installing LaunchAgent..."
mkdir -p "$HOME/Library/LaunchAgents"
sed "s|CLIPBOARD_SYNC_PATH|$SYNC_SCRIPT|g" "$PLIST_SRC" > "$PLIST_DST"

# Unload if already loaded
launchctl unload "$PLIST_DST" 2>/dev/null || true

# Load
launchctl load "$PLIST_DST"

echo ""
echo "=== Done! ==="
echo "Daemon is running. Take a screenshot and press Ctrl+V in Claude Code."
echo ""
echo "Useful commands:"
echo "  Logs:    tail -f /tmp/clipboard-sync.log"
echo "  Stop:    launchctl unload $PLIST_DST"
echo "  Start:   launchctl load $PLIST_DST"
echo "  Restart: launchctl unload $PLIST_DST && launchctl load $PLIST_DST"
echo "  Config:  $CONFIG_FILE"
