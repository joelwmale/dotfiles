# Use vs instead of code
vs () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

# opendb () {
#    [ ! -f .env ] && { echo "No .env file found."; exit 1; }

#    DB_CONNECTION='mysql'
#    DB_HOST=$(grep DB_HOST .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
#    DB_PORT=$(grep DB_PORT .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
#    DB_DATABASE=$(grep DB_DATABASE .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
#    DB_USERNAME=$(grep DB_USERNAME .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)
#    DB_PASSWORD=$(grep DB_PASSWORD .env | grep -v -e '^\s*#' | cut -d '=' -f 2-)

#    DB_URL="${DB_CONNECTION}://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_DATABASE}"

#    echo "Opening ${DB_URL}"
#    open $DB_URL
# }

#########################################
# Productivity stuff                    #
#########################################
# general
alias code='cd ~/Code'

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

#########################################
# Git/hub                               #
#########################################
alias repush='git pull --rebase && git push'
alias gitclean="git checkout master && git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d"
alias publish='git push --set-upstream origin $(git branch | grep \* | cut -d " " -f2)'

# one line log
alias gl='git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short'
alias gr='git pull --rebase && git push'

alias ga='git add .'
alias gc='git commit --verbose'
alias gcm='git commit -m'
alias gcom='git checkout master'
alias gcod='git checkout develop'
alias gca='git commit -a --verbose'
alias gcam='git commit --amend --verbose'

alias grh='git reset --hard'

alias gd='git diff'
alias gds='git diff --stat'

alias gs='git status -s'
alias gc='git checkout'
alias gcb='git checkout -b'

#########################################
# Random stuff                          #
#########################################
alias weather='curl wttr.in/brisbane'

#########################################
# Paths & OS                            #
#########################################
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/.composer/vendor/bin:$PATH
export PATH=$HOME/.npm-global/bin:$PATH

#########################################
# Exports                               #
#########################################
source ~/.aliases