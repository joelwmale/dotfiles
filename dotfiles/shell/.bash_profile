# general
alias code='cd ~/Code'
alias dotfiles='cd ~/Code/dotfiles'
alias q="cd ~ && clear"

alias top="sudo htop"

# code
alias p="./vendor/bin/pest"
alias pc="p --type-coverage"
alias stan="vendor/bin/phpstan analyse --memory-limit=2G"

alias cdump="composer dumpautoload"

# laravel
alias optimize="php artisan optimize"
alias pa="php artisan"
alias dbfresh="pa migrate:fresh --seed"

alias op="php artisan optimize"
alias mfs="pa migrate:fresh --seed"
alias mr="php artisan migrate:rollback"

# frontend stuff
alias twatch="TAILWIND_MODE=watch npx mix watch" 

# misc
alias cat='bat'
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"

# git/hub
alias repush='git pull --rebase && git push'
alias gitclean="git checkout master && git fetch -p && git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -D"
alias publish='git push --set-upstream origin $(git branch | grep \* | cut -d " " -f2)'

alias grc="gh repo clone"

# one line log
alias gl='git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short'
alias gr='git reset'

# misc
alias gaa='git add .'
alias gp='git push'
alias gfa='git fetch --all'
alias grh='git add . && git reset --hard'

# merging
alias gmp='git merge -' # merge previous branch
alias mpb='gcp && git pull && gcp && gmp && git push' # swap to previous branch, pull, swab back to current branch, merge, and push

 # diffs
alias gd='git diff'
alias gds='git diff --stat'

# branches
alias gc='git checkout'
alias gcb='git checkout -b'
alias gcp='git checkout -' # checkout previous branch

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

# Navigation Shortcuts
alias home='clear && cd ~ && ls'
alias downloads='clear && cd ~/Downloads && ls'
alias desktop='clear && cd ~/Desktop && ls'

# composer fix
export COMPOSER_MEMORY_LIMIT=-1

export LDFLAGS="-L/usr/local/opt/libffi/lib"
export CPPFLAGS="-I/usr/local/opt/libffi/include"

export PATH="./vendor/bin:$PATH"
export PATH="/.npm-packages/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"

export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"

eval $(/opt/homebrew/bin/brew shellenv)
