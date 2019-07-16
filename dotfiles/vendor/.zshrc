# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="robbyrussell"

plugins=(
  git
)

autoload -U promptinit; promptinit
prompt pure

source $ZSH/oh-my-zsh.sh
source ~/.bash_profile