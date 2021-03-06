# Use vs instead of code
vs () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

opendb () {
   [ ! -f .env ] && { echo "No .env file found."; exit 1; }

   DB_CONNECTION='mysql'
   DB_HOST=$(grep DB_HOST .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_PORT=$(grep DB_PORT .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_DATABASE=$(grep DB_DATABASE .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_USERNAME=$(grep DB_USERNAME .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
   DB_PASSWORD=$(grep DB_PASSWORD .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)

   DB_URL="${DB_CONNECTION}://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_DATABASE}"

   echo "Opening ${DB_URL}"
   open $DB_URL
}

# general
alias code='cd ~/Code'
alias dotfiles='cd ~/Code/dotfiles'
alias q="cd ~ && clear"

# code
alias codecept="./vendor/bin/codecept"
alias phpunit="php ./vendor/bin/phpunit"
alias cdump="composer dumpautoload"

# laravel
alias pawipe="php artisan config:cache && composer dumpautoload"
alias pa="php artisan"
alias dbfresh="pa migrate:fresh --seed"

# infrastructure
alias tplan='terragrunt plan-all'
alias tapply='terragrunt apply-all'
alias minio='minio server ~/data'

# misc
alias cat='bat'

# git/hub
alias repush='git pull --rebase && git push'
alias gitclean="git checkout master && git fetch -p && git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -D"
alias publish='git push --set-upstream origin $(git branch | grep \* | cut -d " " -f2)'

# one line log
alias gl='git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short'
alias gr='git reset'

# misc
alias ga='git add .'
alias gc='git commit --verbose'
alias gcm='git commit -m'
alias gcom='git checkout master'
alias gcod='git checkout develop'
alias gca='git commit -a --verbose'
alias gcam='git commit --amend --verbose'
alias gf='git fetch'
alias gfa='git fetch --all'
alias grh='git reset --hard'

# stashing
alias gssl='git stash show -p stash@{0}'
alias gsslp='git stash show -p stash@{1}'
alias gsa='git stash apply'
alias gsp='git stash pop'
alias gspua='git stash !git stash show -p | git apply -R'

alias gd='git diff'
alias gds='git diff --stat'

alias gs='git status -s'
alias gc='git checkout'
alias gcb='git checkout -b'

# get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update; sudo gem cleanup'

# networking
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"

# random
alias weather='curl wttr.in/brisbane'

# list all files 
function lals { 
   ls -l | awk '{if (NR!=1) {printf "\033[91m%s\033[0m \033[34m%s:%s\033[0m %s\n", $1, $3, $4, $9 }}'
}

# list all directories
function lald { 
   ls -l | grep '^d' | awk '{ printf "\033[91m%s\033[0m \033[34m%s:%s\033[0m %s\n", $1, $3, $4, $9 }'
}

# paths
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/.composer/vendor/bin:$PATH
export PATH=$HOME/.npm-global/bin:$PATH
export LDFLAGS="-L/usr/local/opt/libffi/lib"
export CPPFLAGS="-I/usr/local/opt/libffi/include"

# custom aliases
source ~/.aliases

# BEGIN SNIPPET: Magento Cloud CLI configuration
HOME=${HOME:-'/Users/joel'}
export PATH="$HOME/"'.magento-cloud/bin':"$PATH"
if [ -f "$HOME/"'.magento-cloud/shell-config.rc' ]; then . "$HOME/"'.magento-cloud/shell-config.rc'; fi # END SNIPPET
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
