#!/usr/bin/env bash
# Zsh, oh-my-zsh, the Spaceship prompt and symlinks for the tracked dotfiles.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

bot 'Shell'

if [ -d "$HOME/.oh-my-zsh" ]; then
    ok 'oh-my-zsh already installed'
else
    action 'installing oh-my-zsh'
    if [ "$DRY_RUN" = 1 ]; then
        echo '  [dry-run] oh-my-zsh install script'
    else
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes fetch_and_run https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh sh
    fi
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM_DIR/themes/spaceship-prompt" ]; then
    action 'installing the spaceship prompt'
    run git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM_DIR/themes/spaceship-prompt"
    run ln -sf "$ZSH_CUSTOM_DIR/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM_DIR/themes/spaceship.zsh-theme"
fi

action 'symlinking dotfiles'
link "$ROOT/dotfiles/vendor/.gitignore"      "$HOME/.gitignore"
link "$ROOT/dotfiles/vendor/.gitattributes"  "$HOME/.gitattributes"
link "$ROOT/dotfiles/vendor/.gitconfig"      "$HOME/.gitconfig"
link "$ROOT/dotfiles/vendor/.zshrc"          "$HOME/.zshrc"
link "$ROOT/dotfiles/shell/.bash_profile"    "$HOME/.bash_profile"
link "$ROOT/dotfiles/shell/.functions"       "$HOME/.functions"
link "$ROOT/dotfiles/vendor/spaceship.zsh"   "$HOME/.config/spaceship.zsh"
link "$ROOT/config/ghostty/config"           "$HOME/.config/ghostty/config"
run touch "$HOME/.aliases" "$HOME/.zshrc.local"
run mkdir -p "$HOME/Code" "$HOME/.zsh"
ok

if command -v fzf >/dev/null 2>&1; then
    action 'setting up fzf key bindings'
    run "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    ok
fi
