# paths
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

# Alias hub to git
eval "$(hub alias -s)"

ZSH_DISABLE_COMPFIX="true"
source $ZSH/oh-my-zsh.sh
source ~/.bash_profile
source ~/.functions
source ~/.aliases

# load plugins
fpath=(~/.zsh $fpath)
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 2> /dev/null

# randomize suggest color
randomSuggestColor=$(( $RANDOM % 2 + 1 ));
if (( $randomSuggestColor == 1)); then
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#D2506F,bold" 
else
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#BB766C,bold"
fi

fpath=($fpath "/Users/joelmale/.zfunctions")
eval "$(/opt/homebrew/bin/brew shellenv)"export PATH="${HOME}/.pyenv/shims:${PATH}"

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