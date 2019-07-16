#!/usr/bin/env bash

function require_cask() {
    running "brew cask install $1"
    brew cask list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        action "brew cask install $1 $2"
        brew cask install $1
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