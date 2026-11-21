#!/usr/bin/env bash
# Node via nvm, global Composer tools and the ghboard CLI.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

bot 'Development tools'

if [ -d "$HOME/.nvm" ]; then
    ok 'nvm already installed'
elif ask 'Install nvm and the current Node LTS?' Y; then
    NVM_VERSION=v0.40.3
    action "installing nvm $NVM_VERSION"
    if [ "$DRY_RUN" = 1 ]; then
        echo "  [dry-run] nvm install script $NVM_VERSION, then nvm install --lts"
    else
        PROFILE=/dev/null fetch_and_run "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" bash &&
            export NVM_DIR="$HOME/.nvm" &&
            . "$NVM_DIR/nvm.sh" && nvm install --lts || error 'nvm install failed'
    fi
    ok
fi

if ! command -v laravel >/dev/null 2>&1 && command -v composer >/dev/null 2>&1; then
    composer_global laravel/installer
fi

if ask 'Install the ghboard CLI (GitHub status dashboard)?' Y; then
    action 'installing ghboard'
    if command -v composer >/dev/null 2>&1; then
        run composer install --working-dir="$ROOT/cli/ghboard" --no-dev --quiet
        link "$ROOT/cli/ghboard/bin/ghboard" "$HOME/bin/ghboard"
        ok
    else
        warn 'composer not found; install Herd first, then run this step again'
    fi
fi

action 'linking CLI scripts into ~/Code/cli'
for script in "$ROOT"/cli/*; do
    [ -f "$script" ] || continue
    link "$script" "$HOME/Code/cli/$(basename "$script")"
    run chmod +x "$script"
done
ok
