#!/bin/bash

# variables
ROOT=$(pwd)

# close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# ask for the administrator password upfront
sudo -v

# keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

bot "Starting installs..."

# set a computer name
if ask 'Set a computer name now?' Y; then
    say 'What computer name would you like to set?'

    # store computer name
    read computerName

    sudo scutil --set ComputerName $computerName
    sudo scutil --set HostName $computerName
    sudo scutil --set LocalHostName $computerName

    ok
    bot 'Computer name has been set successfully'
fi

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
# Dev Tools                                                                   #
###############################################################################

running 'hide xcode-select --install'
# xcode-select --install;ok
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
PROD=$(softwareupdate -l |
  grep "\*.*Command Line" |
  head -n 1 | awk -F"*" '{print $2}' |
  sed -e 's/^ *//' |
  tr -d '\n')
softwareupdate -i "$PROD" --verbose
rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;ok

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

action 'symlink .hushlogin'
rm $HOME/.hushlogin
ln -s $ROOT/dotfiles/shell/.hushlogin $HOME/.hushlogin;ok

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
require_brew gh
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
require_brew php@7.4
require_brew composer
require_brew diff-so-fancy
require_brew zsh-autosuggestions
require_brew awscli

require_brew mysql@5.7
service_start mysql@5.7
brew_link mysql@5.7

require_brew redis
service_start redis

action 'setting mysql@5.7 root password to "root"'
$(brew --prefix mysql)/bin/mysqladmin -u root password root;ok

running 'tapping homebrew-cask'
brew tap homebrew/cask

# casks
require_cask google-chrome
require_cask firefox-developer-edition
require_cask visual-studio-code
require_cask fork
require_cask transmit
require_cask tableplus
require_cask hyper
require_cask spotify
require_cask insomnia
require_cask alfred
require_cask spectacle
require_cask dozer

if ask 'would you like to have spectacle start upon startup?' Y; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Spectacle.app", hidden:false}'
fi

if ask 'would you like to have dozer start upon startup?' Y; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Dozer.app", hidden:false}'
fi

action 'symlink .hyper.js'
rm $HOME/.hyper.js
ln -s $ROOT/dotfiles/vendor/.hyper.js $HOME/.hyper.js;ok

###############################################################################
# Node/NPM                                                                    #
###############################################################################

running 'configure global npm packages to ~/.npm-global'
mkdir ~/.npm-global
npm config set prefix ~/.npm-global;ok

# running 'install pure-prompt'
# npm install --g pure-prompt;ok
# brew install zsh-autosuggestions

###############################################################################
# Composer                                                                    #
###############################################################################

bot 'Installing composer packages'

running 'installing laravel/valet'
composer_global laravel/valet

action 'configuring laravel/valet'
valet install > /dev/null 2>&1
valet park ~/Code > /dev/null 2>&1;ok

###############################################################################
# Shell/misc                                                                  #
###############################################################################

running 'installing powerline font for shell'
cd ~/Desktop
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts;ok

running 'install spaceship prompt'
npm install -g spaceship-prompt;ok

running 'installing zsh autosuggestions'
brew install zsh-autosuggestions;ok