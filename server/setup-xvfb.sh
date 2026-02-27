#!/bin/bash
# Starts Xvfb if not already running and exports DISPLAY
# Source this: source ~/screenshoter/server/setup-xvfb.sh

DISPLAY_NUM=99

if ! pgrep -f "Xvfb :${DISPLAY_NUM}" > /dev/null 2>&1; then
    Xvfb :${DISPLAY_NUM} -screen 0 1024x768x24 &>/dev/null &
    sleep 0.5
    echo "Xvfb started on :${DISPLAY_NUM}"
else
    echo "Xvfb already running on :${DISPLAY_NUM}"
fi

export DISPLAY=:${DISPLAY_NUM}
