# Use vs instead of code
vs () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

#########################################
# Productivity stuff                    #
#########################################
alias pa="php artisan"
alias dbfresh="pa migrate:fresh --seed"
alias code='cd ~/Code'
alias codecept="./vendor/bin/codecept"
alias phpunit="./vendor/bin/phpunit"

alias tplan='terragrunt plan-all'
alias tapply='terragrunt apply-all'
alias minio='minio server ~/data'

alias cat='bat'

#########################################
# Git/hub                               #
#########################################
alias repush='git pull --rebase && git push'
alias gitclean="git checkout master && git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d"

# one line log
alias gl='git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short'
alias gr='git pull --rebase && git push'

alias ga='git add -p'
alias gaa='git add .'
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
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/.composer/vendor/bin:$PATH
export PATH=$HOME/.npm-global/bin:$PATH