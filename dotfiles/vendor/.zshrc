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

SPACESHIP_TIME_SHOW=true
SPACESHIP_PROMPT_ORDER=(
  time          # Time stamps section
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  package       # Package version
  # node          # Node.js section
  ruby          # Ruby section
  elixir        # Elixir section
  xcode         # Xcode section
  swift         # Swift section
  golang        # Go section
  php           # PHP section
  rust          # Rust section
  haskell       # Haskell Stack section
  julia         # Julia section
  # docker        # Docker section
  aws           # Amazon Web Services section
  # gcloud        # Google Cloud Platform section
  venv          # virtualenv section
  conda         # conda virtualenv section
  pyenv         # Pyenv section
  dotnet        # .NET section
  ember         # Ember.js section
  # kubectl       # Kubectl context section
  terraform     # Terraform workspace section
  exec_time     # Execution time
  line_sep      # Line break
  battery       # Battery level and status
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)

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
eval "$(/opt/homebrew/bin/brew shellenv)"
# Set Spaceship ZSH as a prompt
autoload -U promptinit; promptinit
prompt spaceship
