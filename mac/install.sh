#!/bin/bash
# Install script for Mac clipboard sync daemon
# Run this on your Mac: bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/clipboard-sync.sh"
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

# Configure SSH host
read -p "SSH host (from ~/.ssh/config or user@host) [dev]: " SSH_HOST
SSH_HOST="${SSH_HOST:-dev}"
sed -i '' "s|^SSH_HOST=.*|SSH_HOST=\"$SSH_HOST\"|" "$SYNC_SCRIPT"

# Configure remote path
read -p "Remote path to receive.sh [~/screenshoter/server/receive.sh]: " REMOTE_PATH
REMOTE_PATH="${REMOTE_PATH:-~/screenshoter/server/receive.sh}"
sed -i '' "s|^REMOTE_RECEIVE=.*|REMOTE_RECEIVE=\"$REMOTE_PATH\"|" "$SYNC_SCRIPT"

# Test SSH connection
echo "Testing SSH connection..."
if ssh "$SSH_HOST" "echo OK" 2>/dev/null | grep -q OK; then
    echo "SSH connection: OK"
else
    echo "WARNING: SSH connection failed. Check your SSH config."
fi

# Install LaunchAgent
echo "Installing LaunchAgent..."
sed "s|CLIPBOARD_SYNC_PATH|$SYNC_SCRIPT|g" "$PLIST_SRC" > "$PLIST_DST"

# Unload if already loaded
launchctl unload "$PLIST_DST" 2>/dev/null || true

# Load
launchctl load "$PLIST_DST"

echo ""
echo "=== Done! ==="
echo "Daemon is running. Take a screenshot with Xnip and press Ctrl+V in Claude Code."
echo ""
echo "Useful commands:"
echo "  Logs:    tail -f /tmp/clipboard-sync.log"
echo "  Stop:    launchctl unload $PLIST_DST"
echo "  Start:   launchctl load $PLIST_DST"
echo "  Restart: launchctl unload $PLIST_DST && launchctl load $PLIST_DST"
