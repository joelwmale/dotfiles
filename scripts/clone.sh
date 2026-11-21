#!/usr/bin/env bash
# Clones the repositories listed in ~/.config/dotfiles/repos (one owner/repo per line).
# The list stays on the machine so private project names never reach this repo.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

bot 'Cloning repositories'

LIST="$HOME/.config/dotfiles/repos"
CODE="$HOME/Code"
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
warn "private repos need your SSH key added to GitHub first (gh auth login)"

if [ ! -f "$LIST" ]; then
    prompt 'Repositories to clone (owner/repo, space separated, blank to skip)' ''
    [ -z "$ANSWER" ] && { ok 'nothing to clone'; exit 0; }
    run mkdir -p "$(dirname "$LIST")"
    if [ "$DRY_RUN" != 1 ]; then
        for repo in $ANSWER; do echo "$repo"; done > "$LIST"
    fi
fi

[ -f "$LIST" ] || exit 0

ENTRIES=()
while read -r repo; do
    case "$repo" in ''|\#*) continue ;; esac
    ENTRIES+=("$repo|$repo|1")
done < "$LIST"

[ ${#ENTRIES[@]} -gt 0 ] || { ok 'list is empty'; exit 0; }

menu 'Repositories' "${ENTRIES[@]}"

INSTALL_DEPS=0
ask 'Install composer and npm dependencies after cloning?' Y && INSTALL_DEPS=1

for repo in $MENU_RESULT; do
    dest="$CODE/${repo##*/}"
    action "cloning $repo"
    if [ -d "$dest/.git" ]; then
        ok 'already cloned'
    else
        run git clone "git@github.com:$repo.git" "$dest" || { error "clone failed: $repo"; continue; }
    fi

    if [ "$INSTALL_DEPS" = 1 ] && [ -d "$dest" ]; then
        [ -f "$dest/composer.json" ] && run composer install --working-dir="$dest" --quiet
        [ -f "$dest/package.json" ] && run npm install --prefix "$dest" --silent
    fi
done
