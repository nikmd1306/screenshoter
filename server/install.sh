#!/bin/bash
# Server-side install: sets up Xvfb + xclip for Claude Code clipboard image support
# Usage: bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USERNAME="$(whoami)"

echo "=== Screenshoter Server Install ==="

# Install dependencies
echo "Installing xclip and xvfb..."
sudo apt install -y xclip xvfb

# Create screenshots directory
mkdir -p "$HOME/screenshots"

# Install systemd service
echo "Setting up Xvfb systemd service..."
sed "s|YOUR_USERNAME|$USERNAME|g" "$SCRIPT_DIR/xvfb-clipboard.service" | sudo tee /etc/systemd/system/xvfb-clipboard.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable xvfb-clipboard.service
sudo systemctl restart xvfb-clipboard.service

# Add DISPLAY to .bashrc if not already there
if ! grep -q 'export DISPLAY=:99' "$HOME/.bashrc"; then
    echo '' >> "$HOME/.bashrc"
    echo '# Xvfb display for clipboard image support (screenshoter)' >> "$HOME/.bashrc"
    echo 'export DISPLAY=:99' >> "$HOME/.bashrc"
fi

# Verify
sleep 1
export DISPLAY=:99
if xclip -version 2>&1 | grep -q "xclip version"; then
    echo ""
    echo "=== Done! ==="
    echo "Xvfb is running on :99"
    echo "DISPLAY=:99 added to .bashrc"
    echo "receive.sh is ready at: $SCRIPT_DIR/receive.sh"
    echo ""
    echo "Next: set up the Mac side (see mac/ directory)"
else
    echo "ERROR: xclip verification failed"
    exit 1
fi
