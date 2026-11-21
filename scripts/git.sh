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
OP_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
MODE=none
KEY=''
if [ -x "$OP_SIGN" ] && ask 'Sign commits with a 1Password SSH key?' Y; then
    MODE=ssh
    prompt 'Public key (paste from 1Password, blank to skip signing)' "$(git config user.signingkey 2>/dev/null | grep '^ssh-' )"
    KEY="$ANSWER"
    [ -n "$KEY" ] || MODE=none
elif command -v gpg >/dev/null 2>&1; then
    prompt 'GPG signing key id (blank to skip signing)' "$(git config user.signingkey 2>/dev/null | grep -v '^ssh-')"
    KEY="$ANSWER"
    [ -n "$KEY" ] && MODE=gpg
fi

[ -n "$NAME" ] && [ -n "$EMAIL" ] || { warn 'name and email are required, skipping'; exit 0; }

if [ "$DRY_RUN" = 1 ]; then
    echo "  [dry-run] write $LOCAL for $NAME <$EMAIL>${KEY:+ signing ($MODE)}"
    exit 0
fi

{
    echo '[user]'
    printf '\tname = %s\n\temail = %s\n' "$NAME" "$EMAIL"
    if [ "$MODE" != none ]; then
        printf '\tsigningkey = %s\n' "$KEY"
        printf '[commit]\n\tgpgsign = true\n[tag]\n\tgpgsign = true\n'
    fi
    if [ "$MODE" = ssh ]; then
        printf '[gpg]\n\tformat = ssh\n[gpg "ssh"]\n\tprogram = %s\n' "$OP_SIGN"
    elif [ "$MODE" = gpg ]; then
        printf '[gpg]\n\tformat = openpgp\n'
    fi
} > "$LOCAL"
ok "wrote $LOCAL"

if [ "$MODE" = ssh ]; then
    SSH_CONFIG="$HOME/.ssh/config"
    if ! grep -q 'agent.sock' "$SSH_CONFIG" 2>/dev/null && ask 'Use the 1Password SSH agent for all hosts?' Y; then
        run mkdir -p "$HOME/.ssh"
        if [ "$DRY_RUN" = 1 ]; then
            echo "  [dry-run] append IdentityAgent to $SSH_CONFIG"
        else
            printf '\nHost *\n\tIdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"\n' >> "$SSH_CONFIG"
            chmod 600 "$SSH_CONFIG"
        fi
    fi
elif [ ! -f "$HOME/.ssh/id_ed25519" ] && ask 'Create an SSH key for GitHub?' Y; then
    if [ "$ASSUME_YES" = 1 ]; then
        run ssh-keygen -t ed25519 -N '' -C "$EMAIL" -f "$HOME/.ssh/id_ed25519"
    else
        run ssh-keygen -t ed25519 -C "$EMAIL" -f "$HOME/.ssh/id_ed25519"
    fi
    run ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
    say 'Add the key to GitHub:  gh auth login   (or: pbcopy < ~/.ssh/id_ed25519.pub)'
fi
