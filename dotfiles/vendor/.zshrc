export PATH=/opt/homebrew/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/.composer/vendor/bin:$PATH
export PATH=$HOME/.npm-global/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="spaceship"

plugins=(
  git
  brew
)

# disable git stash symbol
SPACESHIP_GIT_STATUS_SHOW_STASH=false

# Alias hub to git
eval "$(hub alias -s)"

ZSH_DISABLE_COMPFIX="true"
source $ZSH/oh-my-zsh.sh
source ~/.bash_profile
source ~/.functions
source ~/.aliases

# load plugins and completions
fpath=(~/.zsh $fpath)

# Initialize completion system (if not already done by oh-my-zsh)
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 2> /dev/null

# randomize suggest color
randomSuggestColor=$(( $RANDOM % 2 + 1 ));
if (( $randomSuggestColor == 1)); then
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#D2506F,bold" 
else
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#BB766C,bold"
fi

# fpath=($fpath "/Users/joelmale/.zfunctions")
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="${HOME}/.pyenv/shims:${PATH}"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm_auto_use() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
    # if node_version != $(nvm version default) and it is not system
  elif [ "$node_version" != "$(nvm version 20.12.1)" ] && [ "$node_version" != "system" ]; then
    echo "Updating nvm to 20.12.1"
    nvm use 20.12.1
  fi
}

add-zsh-hook chpwd nvm_auto_use
nvm_auto_use

# Herd injected PHP binary.
export PATH="/Users/joel/Library/Application Support/Herd/bin/":$PATH

# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/joel/Library/Application Support/Herd/config/php/83/"

# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/joel/Library/Application Support/Herd/config/php/84/"

export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# Herd injected PHP 8.5 configuration.
export HERD_PHP_85_INI_SCAN_DIR="/Users/joel/Library/Application Support/Herd/config/php/85/"

# fzf - Fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview "bat --color=always --style=numbers --line-range=:500 {}"'

# Custom fzf keybindings (more ergonomic)
# Note: Command key isn't available in terminal, using Option/Ctrl alternatives
# Ctrl+R - Search history (standard, keep as is)
# Ctrl+P - Search files (instead of Ctrl+T which conflicts with some terminals)
# Ctrl+G - Change directory (instead of Alt+C)

bindkey -r '^T'  # Remove default Ctrl+T binding
bindkey '^P' fzf-file-widget  # Ctrl+P for files (like VSCode)
bindkey '^G' fzf-cd-widget    # Ctrl+G for directories

# zoxide - Smarter cd
eval "$(zoxide init zsh)"
