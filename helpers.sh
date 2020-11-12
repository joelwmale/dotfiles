#!/usr/bin/env bash

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

function ok() {
    echo -e "$COL_GREEN[ok]$COL_RESET "$1
}

function bot() {
    echo -e "\n$COL_GREEN[._.]$COL_RESET - "$1
}

function running() {
    echo -en "$COL_YELLOW ⇒ $COL_RESET"$1""
}

function action() {
    echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..."
}

function warn() {
    echo -e "$COL_YELLOW[warning]$COL_RESET "$1
}

function error() {
    echo -e "$COL_RED[error]$COL_RESET "$1
}

ask() {
    # https://gist.github.com/davejamesmiller/1965569
    local prompt default reply
    
    if [ "${2:-}" = "Y" ]; then
        prompt="Y/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/N"
        default=N
    else
        prompt="y/n"
        default=
    fi
    
    while true; do
        
        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "
        
        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty
        
        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi
        
        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
        
    done
}

say() {
    echo "$1"
}

function require_cask() {
    brew cask list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        action "brew cask install $1 $2"
        brew cask install $1 > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            error "failed to install $1! skipping..."
        else
            ok
        fi
    fi
}

function require_brew() {
    brew list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        action "brew install $1 $2"
        brew install $1 $2 > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            error "failed to install $1! skipping..."
        else
            ok
        fi
    fi
}

function service_start() {
    action "brew services start $1 $2"
    brew services start $1 $2 > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "failed to start $1! skipping..."
    else
        ok
    fi
}

function brew_link() {
    action "brew link --force $1"
    brew services start $1 > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "failed to force link $1! skipping..."
    else
        ok
    fi
}

function composer_global() {
    action "composer global require $1 $2"
    composer global require $1 $2 > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        error "failed to install $1 globally! skipping..."
    else
        ok
    fi
}