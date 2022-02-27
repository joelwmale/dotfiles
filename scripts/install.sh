#!/bin/bash

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
# Terminal                                                                    #
###############################################################################

running 'hide last login line when starting terminal'
touch $HOME/.hushlogin;ok

if [ ! -d $HOME/.oh-my-zsh ]; then
    action 'install oh-my-zsh'
    curl -L https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh;ok
else
    if ask 'Reinstall oh-my-zsh?' Y; then
        action 'reinstall oh-my-zsh'
        rm -rf $HOME/.oh-my-zsh
        curl -L https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh;ok
    fi
fi

###############################################################################
# Directories & configurations                                                #
###############################################################################

bot 'Setting up symlinks...'

action 'add global gitignore'
rm $HOME/.gitignore
ln -s $ROOT/dotfiles/vendor/.gitignore $HOME/.gitignore;ok

action 'add global gitattributes'
rm $HOME/.gitattributes
ln -s $ROOT/dotfiles/vendor/.gitattributes $HOME/.gitattributes;ok

action 'symlink .bash_profile'
rm $HOME/.bash_profile
ln -s $ROOT/dotfiles/shell/.bash_profile $HOME/.bash_profile;ok

action 'symlink .functions'
rm $HOME/.functions
ln -s $ROOT/dotfiles/shell/.functions $HOME/.functions;ok

action 'setting up vim'
rm $HOME/.vimrc
ln -s $ROOT/dotfiles/vendor/.vimrc $HOME/.vimrc
rm $HOME/.vim
ln -s $ROOT/dotfiles/vendor/.vim $HOME/.vim;ok

action 'symlink z'
rm $HOME/.z.sh
ln -s $ROOT/dotfiles/vendor/z.sh $HOME/z.sh;ok

action 'touch .aliases'
rm $HOME/.aliases
touch $HOME/.aliases;ok

action 'symlink .zshrc'
rm $HOME/.zshrc
ln -s $ROOT/dotfiles/vendor/.zshrc $HOME/.zshrc;ok

action 'creating ~/.zsh'
rm -rf $HOME/.zsh
mkdir $HOME/.zsh

action 'symlink .gitconfig'
rm $HOME/.gitconfig
ln -s $ROOT/dotfiles/vendor/.gitconfig $HOME/.gitconfig;ok

action 'symlink .mackup.cfg'
rm $HOME/.mackup.cfg
ln -s $ROOT/dotfiles/vendor/.mackup.cfg $HOME/.mackup.cfg;ok

action 'symlink .hyper.js'
rm $HOME/.hyper.js
ln -s $ROOT/dotfiles/vendor/.hyper.js $HOME/.hyper.js;ok

# Create directories
action 'creating code directory at ~/Code'
mkdir -p $HOME/Code;ok

###############################################################################
# Default cleanup                                                             #
###############################################################################

bot 'cleaning up a few things'

action 'deleting garage band'
sudo rm -rf /Applications/GarageBand.app;ok

action 'deleting imovie'
sudo rm -rf /Applications/iMovie.app;ok

action 'deleting keynote'
sudo rm -rf /Applications/Keynote.app;ok

action 'deleting podcasts'
sudo rm -rf /Applications/Podcasts.app;ok

###############################################################################
# Brew                                                                        #
###############################################################################

bot 'checking brew installation...'

brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
    action "installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

bot 'installing brew apps...'

require_brew git
require_brew gh
require_brew node
require_brew pkg-config
require_brew wget
require_brew httpie
require_brew ncdu
require_brew hub
require_brew ack
require_brew bat
require_brew doctl
require_brew yarn
require_brew diff-so-fancy
require_brew zsh-autosuggestions
require_brew awscli
require_brew tree
require_brew mas
require_brew dockutil
require_brew htop
require_brew mackup

require_brew php@8.1
service_start php@8.1
brew link --overwrite --force php@8.1

require_brew composer

require_brew mariadb
service_start mariadb
brew_link mariadb

require_brew redis
service_start redis

running 'tapping homebrew-cask'
brew tap homebrew/cask;ok

running 'tapping homebrew/cask-versions'
brew tap homebrew/cask-versions;ok

bot 'installing brew casks...'

# casks
require_cask brave-browser
require_cask firefox-developer-edition
require_cask visual-studio-code
require_cask fork
require_cask transmit
require_cask tableplus
require_cask hyper
require_cask spotify
require_cask 1password
require_cask insomnia
require_cask alfred
require_cask spectacle
require_cask bartender
require_cask docker
require_cask forklift
require_cask fantastical
require_cask google-drive
require_cask dropbox
require_cask slack
require_cask the-unarchiver

bot 'installing mac app store apps...'

# mac app store
if ask 'have you signed into the app store?' Y; then
    action 'mas: install spark'
    mas install 1176895641 > /dev/null 2>&1;ok

    action 'mas: install things'
    mas install 904280696 > /dev/null 2>&1;ok

    action 'mas: install amphetamine'
    mas install 937984704 > /dev/null 2>&1;ok

    action 'mas: install bear'
    mas install 1091189122 > /dev/null 2>&1;ok
fi

if ask 'would you like to have spectacle start upon startup?' Y; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Spectacle.app", hidden:false}'
fi

###############################################################################
# Node/NPM                                                                    #
###############################################################################

bot 'configurating node & npm and installing packages'

running 'configure global npm packages to ~/.npm-global'
mkdir ~/.npm-packages
npm config set prefix ~/.npm-packages;ok

running 'installing gulp globally'
npm install -g gulp > /dev/null 2>&1;ok

running 'install vsce'
npm install -g vsce;ok

###############################################################################
# Composer                                                                    #
###############################################################################

bot 'installing global composer packages'

running 'installing laravel/valet'
composer_global laravel/valet;ok

action 'configuring laravel/valet'
valet install > /dev/null 2>&1
valet tld test > /dev/null 2>&1
valet park ~/Code > /dev/null 2>&1;ok

action 'installing laravel/installer'
composer global require laravel/installer > /dev/null 2>&1;ok

###############################################################################
# Shell                                                                       #
###############################################################################

running 'installing powerline font for shell'
cd ~/Desktop
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts;ok

running 'install spaceship prompt'
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme";ok

running 'installing zsh autosuggestions'
brew install zsh-autosuggestions;ok

running 'installing zsh git completion'
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh -o ~/.zsh/_git-completion;ok

running 'installing zsh autocomplete git completion'
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions;ok