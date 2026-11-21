#!/usr/bin/env bash
# Prints what cannot be scripted, for the apps that are actually installed.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

has() { [ -d "/Applications/$1.app" ]; }
item() { echo "  [ ] $1"; }

bot 'Still to do by hand'

echo "Sign in"
has 1Password && item "1Password: sign in, enable the SSH agent (Settings > Developer)"
has Setapp && item "Setapp: sign in"
has "Google Drive" && item "Google Drive: sign in"
has Slack && item "Slack, Discord, Telegram: sign in"
has Tailscale && item "Tailscale: sign in"
command -v gh >/dev/null 2>&1 && item "GitHub: gh auth login"

echo "Permissions (System Settings > Privacy & Security)"
has Ghostty && item "Full Disk Access: Ghostty"
has Alfred\ 5 && item "Accessibility: Alfred"
has "Rectangle Pro" && item "Accessibility: Rectangle Pro"
has BetterDisplay && item "Screen Recording: BetterDisplay"

echo "First launch"
has Herd && item "Herd: open once to finish PHP and Composer setup"
has Docker && item "Docker: open once and accept the terms"
has "Android Studio" && item "Android Studio: run the setup wizard"
has Alfred\ 5 && item "Alfred: point sync at your Google Drive folder"

echo "Then"
item "Restart, so the macOS preferences fully apply"
