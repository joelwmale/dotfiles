#!/usr/bin/env bash
# Writes ~/.gitconfig.local, which the tracked gitconfig includes. Keeps identity and keys out of the repo.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

bot 'Git identity'

LOCAL="$HOME/.gitconfig.local"

if [ -f "$LOCAL" ] && ! ask "$LOCAL exists. Overwrite it?" N; then
    ok 'kept existing identity'
    exit 0
fi

prompt 'Git name' "$(git config user.name 2>/dev/null)"
NAME="$ANSWER"
prompt 'Git email' "$(git config user.email 2>/dev/null)"
EMAIL="$ANSWER"
prompt 'GPG signing key id (blank to skip signing)' "$(git config user.signingkey 2>/dev/null)"
KEY="$ANSWER"

if [ -n "$KEY" ] && ! command -v gpg >/dev/null 2>&1; then
    warn 'gpg is not installed (brew install gnupg pinentry-mac); signing left off'
    KEY=''
fi

[ -n "$NAME" ] && [ -n "$EMAIL" ] || { warn 'name and email are required, skipping'; exit 0; }

if [ "$DRY_RUN" = 1 ]; then
    echo "  [dry-run] write $LOCAL for $NAME <$EMAIL>${KEY:+ signing with $KEY}"
    exit 0
fi

{
    echo '[user]'
    printf '\tname = %s\n\temail = %s\n' "$NAME" "$EMAIL"
    if [ -n "$KEY" ]; then
        printf '\tsigningkey = %s\n' "$KEY"
        printf '[commit]\n\tgpgsign = true\n[tag]\n\tgpgsign = true\n[gpg]\n\tformat = openpgp\n'
    fi
} > "$LOCAL"
ok "wrote $LOCAL"

if [ ! -f "$HOME/.ssh/id_ed25519" ] && ask 'Create an SSH key for GitHub?' Y; then
    if [ "$ASSUME_YES" = 1 ]; then
        run ssh-keygen -t ed25519 -N '' -C "$EMAIL" -f "$HOME/.ssh/id_ed25519"
    else
        run ssh-keygen -t ed25519 -C "$EMAIL" -f "$HOME/.ssh/id_ed25519"
    fi
    run ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
    say 'Add the key to GitHub:  gh auth login   (or: pbcopy < ~/.ssh/id_ed25519.pub)'
fi
