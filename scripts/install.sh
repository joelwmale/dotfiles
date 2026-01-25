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
rm -f $HOME/.gitignore
ln -sf $ROOT/dotfiles/vendor/.gitignore $HOME/.gitignore;ok

action 'add global gitattributes'
rm -f $HOME/.gitattributes
ln -sf $ROOT/dotfiles/vendor/.gitattributes $HOME/.gitattributes;ok

action 'symlink .bash_profile'
rm -f $HOME/.bash_profile
ln -sf $ROOT/dotfiles/shell/.bash_profile $HOME/.bash_profile;ok

action 'symlink .functions'
rm -f $HOME/.functions
ln -sf $ROOT/dotfiles/shell/.functions $HOME/.functions;ok

action 'touch .aliases'
rm -f $HOME/.aliases
touch $HOME/.aliases;ok

action 'symlink .zshrc'
rm -f $HOME/.zshrc
ln -sf $ROOT/dotfiles/vendor/.zshrc $HOME/.zshrc;ok

action 'creating ~/.zsh'
rm -rf $HOME/.zsh
mkdir $HOME/.zsh

action 'symlink .gitconfig'
rm -f $HOME/.gitconfig
ln -sf $ROOT/dotfiles/vendor/.gitconfig $HOME/.gitconfig;ok

action 'symlink .hyper.js'
rm -f $HOME/.hyper.js
ln -sf $ROOT/dotfiles/vendor/.hyper.js $HOME/.hyper.js;ok

action 'symlink .tmux.conf'
rm -f $HOME/.tmux.conf
ln -sf $ROOT/dotfiles/vendor/.tmux.conf $HOME/.tmux.conf;ok

# Create directories
action 'creating code directory at ~/Code'
mkdir -p $HOME/Code;ok

action 'creating cli directory at ~/Code/cli'
mkdir -p $HOME/Code/cli;ok

action 'symlinking CLI scripts'
for script in $ROOT/cli/*; do
    if [ -f "$script" ]; then
        ln -sf "$script" "$HOME/Code/cli/$(basename $script)"
        chmod +x "$HOME/Code/cli/$(basename $script)"
    fi
done;ok

action 'creating .config directory at ~/.config'
mkdir -p $HOME/.config;ok

action 'symlink spaceship.zsh'
ln -sf $ROOT/dotfiles/vendor/spaceship.zsh $HOME/.config/spaceship.zsh;ok

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

brew_install git
brew_install gh
brew_install node
brew_install pkg-config
brew_install wget
brew_install httpie
brew_install ncdu
brew_install hub
brew_install ack
brew_install bat
brew_install doctl
brew_install yarn
brew_install diff-so-fancy
brew_install zsh-autosuggestions
brew_install awscli
brew_install tree
brew_install mas
brew_install dockutil
brew_install htop
brew_install composer
brew_install jordanbaird-ice
brew_install go
brew_install git-filter-repo
brew_install tesseract

# Productivity tools
brew_install fzf
brew_install zoxide
brew_install tmux
brew_install eza
brew_install git-delta
brew_install lazygit
brew_install fd
brew_install ripgrep
brew_install yazi
brew_install jq
brew_install stripe
brew_install stripe-mock
brew_install node@22
brew_install python@3.13
brew_install python@3.14
brew_install clickhouse

brew_install mysql@8.0
service_start mysql@8.0

# configure mysql
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';"

brew_install redis
service_start redis

running 'tapping homebrew-cask'
brew_install tap homebrew/cask;ok

running 'tapping homebrew/cask-versions'
brew_install tap homebrew/cask-versions;ok

bot 'installing brew casks...'

# casks
cask_install brave-browser
cask_install visual-studio-code
cask_install fork
cask_install transmit
cask_install hyper
cask_install spotify
cask_install 1password
cask_install httpie
cask_install alfred
cask_install fantastical
cask_install google-drive
cask_install dropbox
cask_install slack
cask_install the-unarchiver
cask_install rectangle
cask_install helo
cask_install telegram
cask_install discord
cask_install setapp
cask_install herd
cask_install ghostty
cask_install warp
cask_install cursor
cask_install alt-tab
cask_install bettertouchtool
cask_install daisydisk

running 'tapping shopify/shopify'
brew tap shopify/shopify
brew_install themekit;ok

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

if ask 'would you like to have rectangle start upon startup?' Y; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Rectangle.app", hidden:false}'
fi

# Claude Code setup
echo ""
read -p "Install Claude Code? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash $ROOT/scripts/install-claude-code.sh || warn "Claude Code setup had issues"
else
    warn "Skipping Claude Code installation"
fi

###############################################################################
# Preferences                                                #
###############################################################################

bot 'Setting up preferences...'

cp $ROOT/dotfiles/preferences/* ~/Library/Preferences/;ok

###############################################################################
# Node/NPM                                                                    #
###############################################################################

bot 'configurating node & npm and installing packages'

running 'configure global npm packages to ~/.npm-global'
mkdir ~/.npm-global
npm config set prefix ~/.npm-global;ok

running 'installing gulp globally'
npm install -g gulp > /dev/null 2>&1;ok

running 'installing aicommits'
npm install -g aicommits > /dev/null 2>&1;ok

###############################################################################
# Composer                                                                    #
###############################################################################

bot 'installing global composer packages'

action 'installing laravel/installer'
composer_global laravel/installer

# action 'installing laravel/valet'
# composer_global laravel/valet

# action 'configuring laravel/valet'
# valet install > /dev/null 2>&1
# valet tld test > /dev/null 2>&1
# valet park ~/Code > /dev/null 2>&1;ok

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

running 'installing nvm'
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash;ok

running 'setting up fzf key bindings'
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish;ok

###############################################################################
# Rosetta                                                                     #
###############################################################################

running 'installing rosetta'
softwareupdate --install-rosetta;ok
