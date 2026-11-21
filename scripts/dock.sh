#!/usr/bin/env bash
# Rebuilds the Dock from apps that are actually installed.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

bot 'Dock'

if ! command -v dockutil >/dev/null 2>&1 && [ "$DRY_RUN" != 1 ]; then
    warn 'dockutil is not installed (it is in the packages step), skipping'
    exit 0
fi

CANDIDATES=(
    "Brave Browser" "Fantastical" "Ghostty" "Visual Studio Code" "Fork"
    "Slack" "Discord" "Figma" "Claude"
)
ENTRIES=()
for app in "${CANDIDATES[@]}"; do
    if [ -d "/Applications/$app.app" ] || [ "$DRY_RUN" = 1 ]; then
        ENTRIES+=("$app|$app|1")
    fi
done

menu 'Dock apps' "${ENTRIES[@]}"

if [ -z "$MENU_RESULT" ]; then
    ok 'nothing selected, Dock left alone'
    exit 0
fi

run mkdir -p "$BACKUP_DIR"
run cp "$HOME/Library/Preferences/com.apple.dock.plist" "$BACKUP_DIR/com.apple.dock.plist"
run dockutil --no-restart --remove all
for app in "${CANDIDATES[@]}"; do
    case "|${MENU_RESULT// /|}|" in
        *"|${app// /|}|"*) run dockutil --no-restart --add "/Applications/$app.app" ;;
    esac
done
run killall Dock
ok
