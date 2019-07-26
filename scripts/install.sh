#!/bin/bash

# variables
ROOT=$(pwd)

bot "Starting installs..."

# update existing hosts file with someonewhocares.org
if ask 'Overwrite /etc/hosts with the ad-blocking hosts file from someonewhocares.org? (from ./configs/hosts file)' Y; then
    action "cp /etc/hosts /etc/hosts.backup"
    sudo cp /etc/hosts /etc/hosts.backup
    ok
    action "cp ../files/hosts /etc/hosts"
    sudo cp ./config/hosts /etc/hosts
    ok
    bot "/etc/hosts file has been updated. Backup saved in /etc/hosts.backup"
else
    ok "skipped";
fi

###############################################################################
# Terminal                                                                    #
###############################################################################

running 'hide last login line when starting terminal'
touch $HOME/.hushlogin;ok

action 'install oh-my-zsh'
rm -rf $HOME/.oh-my-zsh
curl -L https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh;ok

###############################################################################
# Directories & configurations                                                #
###############################################################################

bot 'Setting up symlinks...'

action 'add global gitignore'
ln -s $ROOT/dotfiles/shell/.global-gitingore $HOME/.global-gitignore
git config --global core.excludesfile $HOME/.global-gitignore;ok

action 'symlink .bash_profile'
rm $HOME/.bash_profile
ln -s $ROOT/dotfiles/shell/.bash_profile $HOME/.bash_profile;ok

action 'symlink .zshrc'
rm $HOME/.zshrc
ln -s $ROOT/dotfiles/vendor/.zshrc $HOME/.zshrc;ok

action 'symlink .gitconfig'
rm $HOME/.gitconfig
ln -s $ROOT/dotfiles/vendor/.gitconfig $HOME/.gitconfig;ok

# Create directories
action 'creating code directory at ~/Code'
mkdir -p $HOME/Code;ok

###############################################################################
# Brew                                                                        #
###############################################################################

bot 'checking brew installation...'

brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
    action "installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    if [[ $? != 0 ]]; then
        error "unable to install homebrew, aborting script.."
        exit -1
    fi
else
    if ask 'run brew update && upgrade?' Y; then
        action "updating homebrew..."
        brew update
        ok "homebrew updated"
        action "upgrading brew packages..."
        brew upgrade
        ok "brews upgraded"
    else
        ok "skipped brew package upgrades."
    fi
fi

require_brew git
require_brew node
require_brew pkg-config
require_brew wget --overwrite
require_brew httpie
require_brew ncdu
require_brew hub
require_brew ack
require_brew bat
require_brew doctl
require_brew yarn
require_brew php@7.3
require_brew composer
require_brew diff-so-fancy

require_brew mariadb
start_service mariadb

require_brew redis
start_service redis

running 'tapping brew-cask'
brew tap caskroom/cask

# casks
require_cask google-chrome
require_cask visual-studio-code
require_cask fork
require_cask transmit
require_cask sequel-pro
require_cask hyper
require_cask spotify
require_cask insomnia
require_cask alfred
require_cask spectacle

if ask 'would you like to have spectacle start upon startup?' Y; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Spectacle.app", hidden:false}'
fi

action 'symlink .hyper.js'
rm $HOME/.hyper.js
ln -s $ROOT/dotfiles/vendor/.hyper.js $HOME/.hyper.js;ok

###############################################################################
# Node/NPM                                                                    #
###############################################################################

running 'install pure-prompt'
npm install --g pure-prompt;ok

echo 'Install zsh-autosuggestions'
echo '---------------------------'
brew install zsh-autosuggestions

###############################################################################
# Composer                                                                    #
###############################################################################

bot 'Installing composer packages'

running 'installing laravel/valet'
composer_global laravel/valet

action 'configuring laravel/valet'
valet install
valet park ~/Code
valet tld app;ok

running 'installing hirak/prestissimo'
composer_global hirak/prestissimo

running "installing spatie/phpunit-watcher"
composer_global spatie/phpunit-watcher