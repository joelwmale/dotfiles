#!/usr/bin/env bash
# One-line setup for a blank Mac:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/joelwmale/dotfiles/master/install.sh)"
# Installs the Xcode command line tools, clones the repo over HTTPS, runs ./bootstrap.
# Extra arguments go to bootstrap (for example --yes).

set -u

REPO_HTTPS="https://github.com/joelwmale/dotfiles.git"
REPO_SSH="git@github.com:joelwmale/dotfiles.git"
DEST="${DOTFILES_DIR:-$HOME/Code/dotfiles}"

if ! xcode-select -p >/dev/null 2>&1; then
    echo "Installing the Xcode command line tools. Accept the dialog that appears."
    xcode-select --install >/dev/null 2>&1
    until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

if [ -d "$DEST/.git" ]; then
    echo "$DEST exists, updating."
    git -C "$DEST" pull --ff-only || echo "Could not fast-forward; continuing with what is there."
else
    mkdir -p "$(dirname "$DEST")"
    git clone "$REPO_HTTPS" "$DEST" || { echo "Clone failed."; exit 1; }
fi

cd "$DEST" || exit 1
./bootstrap "$@"
rc=$?

# The HTTPS clone has no push access; switch to SSH once a key works.
if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    git remote set-url origin "$REPO_SSH"
fi

exit $rc
