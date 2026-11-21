#!/usr/bin/env bash
# Computer name, hosts file, developer prerequisites and bundled-app cleanup.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

bot 'System'

if ! xcode-select -p >/dev/null 2>&1; then
    warn 'Xcode command line tools are missing'
    run xcode-select --install
    say 'Finish the installer that just opened, then run ./bootstrap again.'
    [ "$DRY_RUN" = 1 ] || exit 2
fi

if [ "$(uname -m)" = arm64 ] && ! /usr/bin/pgrep -q oahd; then
    if ask 'Install Rosetta (needed for Intel-only apps)?' Y; then
        run softwareupdate --install-rosetta --agree-to-license
    fi
fi

if ask 'Set a computer name?' N; then
    prompt 'Computer name' "$(scutil --get ComputerName 2>/dev/null)"
    if [ -n "$ANSWER" ]; then
        run sudo scutil --set ComputerName "$ANSWER"
        HOST_NAME=$(echo "$ANSWER" | tr -cs 'A-Za-z0-9' '-' | sed 's/^-//; s/-$//')
        run sudo scutil --set HostName "$HOST_NAME"
        run sudo scutil --set LocalHostName "$HOST_NAME"
        ok
    fi
fi

if ask 'Replace /etc/hosts with the ad-blocking hosts file in config/hosts (backup kept)?' N; then
    [ -e /etc/hosts.backup ] || run sudo cp /etc/hosts /etc/hosts.backup
    run sudo cp "$ROOT/config/hosts" /etc/hosts
    ok '/etc/hosts replaced; the original is in /etc/hosts.backup'
fi

running 'hide the last-login line in new terminals'
run touch "$HOME/.hushlogin"
ok

if ask 'Let Ghostty and other terminals run unsigned developer tools (Developer Tools privacy pane)?' Y; then
    run sudo spctl developer-mode enable-terminal
    say 'Then enable your terminal under System Settings > Privacy & Security > Developer Tools.'
fi

BUNDLED=()
for app in GarageBand iMovie Keynote Pages Numbers; do
    [ -d "/Applications/$app.app" ] && BUNDLED+=("$app|$app|0")
done
if [ ${#BUNDLED[@]} -gt 0 ]; then
    menu 'Remove bundled Apple apps' "${BUNDLED[@]}"
    for app in $MENU_RESULT; do
        action "removing $app"
        run sudo rm -rf "/Applications/$app.app" && ok
    done
fi
