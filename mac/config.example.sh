#!/bin/bash
# Copy this file to config.sh and edit:
#   cp config.example.sh config.sh

SSH_HOST="dev"                                    # SSH host from ~/.ssh/config (or user@host)
REMOTE_RECEIVE="~/screenshoter/server/receive.sh" # Path to receive.sh on server
POLL_INTERVAL=1                                    # Seconds between clipboard checks
