# Screenshoter

Paste screenshots into [Claude Code](https://docs.anthropic.com/en/docs/claude-code) over SSH with Ctrl+V — just like working locally.

## The Problem

When connected to a remote server via SSH, Claude Code can't access your local clipboard:

```
No image found in clipboard. You're SSH'd; try scp?
```

## How It Works

```
Mac                              Remote Server
┌──────────────┐    SSH pipe    ┌──────────────────┐
│ Xnip / any   │──────────────>│ receive.sh        │
│ screenshot    │               │   ↓               │
│ tool          │               │ saves to file     │
│   ↓           │               │   ↓               │
│ clipboard     │               │ xclip loads into  │
│   ↓           │               │ X11 clipboard     │
│ daemon polls  │               │   ↓               │
│ every 1s      │               │ Ctrl+V in Claude  │
│ via pngpaste  │               │ Code works!       │
└──────────────┘               └──────────────────┘
```

A background daemon on your Mac watches the clipboard for new images. When detected, it pipes the image over SSH to the server, where it's loaded into a virtual X11 clipboard via Xvfb + xclip. Claude Code reads from this clipboard on Ctrl+V.

## Prerequisites

- **Mac**: Homebrew, SSH access to server configured in `~/.ssh/config`
- **Server**: Ubuntu/Debian with `sudo` access, systemd

## Installation

### 1. Server Setup

SSH into your server and run:

```bash
git clone https://github.com/nikmd1306/screenshoter.git ~/screenshoter
bash ~/screenshoter/server/install.sh
```

This installs `xclip` + `xvfb`, starts a virtual X11 display on `:99`, and adds `DISPLAY=:99` to your `.bashrc`.

**Important:** Reconnect your SSH session (or run `export DISPLAY=:99`) to pick up the new environment variable.

### 2. Mac Setup

On your Mac:

```bash
git clone https://github.com/nikmd1306/screenshoter.git ~/screenshoter
bash ~/screenshoter/mac/install.sh
```

The installer will ask for:
- **SSH host** — the host from your `~/.ssh/config` (e.g., `my-server`)
- **Remote path** — path to `receive.sh` on the server (default: `~/screenshoter/server/receive.sh`)

It tests the SSH connection and installs a LaunchAgent that runs automatically.

### 3. Test

Take a screenshot with Xnip (or any tool that copies to clipboard), then Ctrl+V in Claude Code on the server. You should see the image appear.

## Configuration

Settings are stored in `mac/config.sh` (created by the installer, gitignored). Edit it to change:

| Variable | Default | Description |
|---|---|---|
| `SSH_HOST` | `dev` | SSH host (from `~/.ssh/config` or `user@host`) |
| `REMOTE_RECEIVE` | `~/screenshoter/server/receive.sh` | Path to receive script on server |
| `POLL_INTERVAL` | `1` | Seconds between clipboard checks |

You can also re-run `bash mac/install.sh` to reconfigure interactively. `git pull` won't touch your config.

## FAQ

**Does it survive Mac reboot?**

Yes. The LaunchAgent starts automatically on login and restarts if the process crashes.

**What if SSH is unavailable?**

The daemon keeps running. Failed transfers are logged and will be retried when the same image is still in the clipboard and SSH recovers. No images are lost — they stay in the clipboard until a new one replaces them.

**Does it work with any screenshot tool?**

Yes — anything that puts a PNG image into the macOS clipboard (Xnip, CleanShot X, native Cmd+Shift+4, etc.).

**Where are screenshots stored on the server?**

In `~/screenshots/`, with a symlink `latest.png` pointing to the most recent one.

## Useful Commands

```bash
# Mac — view logs
tail -f /tmp/clipboard-sync.log

# Mac — restart daemon
launchctl unload ~/Library/LaunchAgents/com.screenshoter.clipboard-sync.plist
launchctl load ~/Library/LaunchAgents/com.screenshoter.clipboard-sync.plist

# Mac — stop daemon
launchctl unload ~/Library/LaunchAgents/com.screenshoter.clipboard-sync.plist

# Server — check Xvfb status
sudo systemctl status xvfb-clipboard

# Server — test clipboard manually
xclip -selection clipboard -t image/png -o > /tmp/test.png && echo "OK" || echo "Empty"
```

## Troubleshooting

**"pngpaste not found"** — Run `brew install pngpaste`.

**Daemon starts but no sync** — Check `tail -f /tmp/clipboard-sync.log`. Verify SSH works: `ssh <your-host> echo OK`.

**"No image found in clipboard" in Claude Code** — Make sure you reconnected SSH after server install (need `DISPLAY=:99` in environment). Check: `echo $DISPLAY` should show `:99`.

**Images not detected after screenshot** — Some tools need a moment. If using Xnip, ensure the screenshot is completed (not just the selection overlay).

## License

MIT
