#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

bot 'General ui/ux'

running 'Disable sound effects on boot'
sudo nvram SystemAudioVolume=" ";ok

running 'Set sidebar icon size to medium'
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2;ok

running 'Increase window resize speed for Cocoa applications'
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001;ok

running 'Expand save panel by default'
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true;ok

running 'Expand print panel by default'
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true;ok

running 'Save to disk and not icloud by default'
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false;ok

running 'Automatically quit printer app once the print jobs complete'
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true;

running "Disable the 'Are you sure you want to open this application?' dialog"
defaults write com.apple.LaunchServices LSQuarantine -bool false;ok

running 'Disable resume system-wide'
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false;ok

running 'Disable automatic termination of inactive apps'
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true;ok

running 'Display IP, hostname, OS version, etc. at login screen'
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName;ok

running 'Disable smart quotes'
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false;ok

running 'Disable smart dashes'
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false;ok

running 'Hide battery percent, show battery time remaining'
defaults write com.apple.menuextra.battery ShowPercent -string "NO"
defaults write com.apple.menuextra.battery ShowTime -string "YES";ok

###############################################################################
# SSD-specific tweaks                                                         #
###############################################################################

bot 'SSD tweaks'

running 'Disable local Time Machine snapshots'
sudo tmutil disablelocal;ok

running 'Disable hibernation'
sudo pmset -a hibernatemode 0;ok

# Disable the sudden motion sensor as it’s not useful for SSDs
running 'Disable sudden motion sensor'
sudo pmset -a sms 0;ok

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

bot 'Configuring trackpad, mouse, keyboard, bluetooth accessories and input';

running 'Increase sound quality for bluetooth headphones/headsets'
defaults write com.apple.BluetoothAudioAgent 'Apple Bitpool Max (editable)' 80
defaults write com.apple.BluetoothAudioAgent 'Apple Bitpool Min (editable)' 80
defaults write com.apple.BluetoothAudioAgent 'Apple Initial Bitpool (editable)' 80
defaults write com.apple.BluetoothAudioAgent 'Apple Initial Bitpool Min (editable)' 80
defaults write com.apple.BluetoothAudioAgent 'Negotiated Bitpool' 80
defaults write com.apple.BluetoothAudioAgent 'Negotiated Bitpool Max' 80
defaults write com.apple.BluetoothAudioAgent 'Negotiated Bitpool Min' 80;ok

running  'Full keyboard access for all controls'
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3;ok

running 'Set language and text formats'
defaults write NSGlobalDomain AppleLanguages -array 'en'
defaults write NSGlobalDomain AppleLocale -string 'en_AU@currency=AUD'
defaults write NSGlobalDomain AppleMeasurementUnits -string 'Centimeters'
defaults write NSGlobalDomain AppleMetricUnits -bool true;ok

running 'Set timezone to Australia/Brisbane'
systemsetup -settimezone 'Australia/Brisbane' > /dev/null;ok

running 'Disable auto correct'
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false;ok

running 'Allow key repeating'
defaults write -g ApplePressAndHoldEnabled -bool false;ok

running 'Set keyboard repeat rate'
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15;ok

running 'Disable natural scrolling'
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false;ok

running 'Stop itunes from launching on media key press'
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null;ok

running 'Stop itunes from opening when a device is plugged in'
defaults write com.apple.iTunesHelper ignore-devices 1;ok

###############################################################################
# Spotlight                                                                      #
###############################################################################

bot 'Configuring spotlight'

running 'Stop spotlight from indexing'
launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist;ok

###############################################################################
# Screen                                                                      #
###############################################################################

bot 'Configuring screen settings'

running 'Require password immediately after sleep or screen saver'
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0;ok

###############################################################################
# Screenshots                                                                 #
###############################################################################

bot 'Configuring screenshot settings'

running 'Save screenshots to the desktop'
defaults write com.apple.screencapture location -string "${HOME}/Desktop";ok

running 'Save screenshots as png'
defaults write com.apple.screencapture type -string "png";ok

running 'Disable shadow in screenshots'
defaults write com.apple.screencapture disable-shadow -bool true;ok

###############################################################################
# Finder                                                                      #
###############################################################################

bot 'Configuring finder settings'

running 'Set default finder window ~/Desktop'
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/";ok

running 'Show all file extensions'
defaults write NSGlobalDomain AppleShowAllExtensions -bool true;ok

running 'Show hidden files'
defaults write com.apple.finder AppleShowAllFiles -bool true;ok

running 'Allow text selection in Quick Look'
defaults write com.apple.finder QLEnableTextSelection -bool true;ok

running 'Show current path as finder title'
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true;ok

running 'Search current folder when searching by default'
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf";ok

running 'Disable warning when changing a file extension'
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false;ok

running 'Disable DS_Store files on network volumes'
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true;ok

running 'Automatically open a new Finder window when a volume is mounted'
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true;ok

running 'Disable disk image verification'
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true;ok

running 'Use list view in all finder windows'
defaults write com.apple.finder FXPreferredViewStyle -string "clmv";ok

running 'Disable warning when emptying trash'
defaults write com.apple.finder WarnOnEmptyTrash -bool false;ok

running 'Show ~/Library folder'
chflags nohidden ~/Library;ok

running 'Show ~/Users folder'
chflags nohidden /Users;ok

# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”

defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

bot 'Setting up dock, dashboard and hot corners'

running 'Stop bouncing in dock'
defaults write com.apple.dock no-bouncing -bool true;ok

running 'Automatically hide and show the dock'
defaults write com.apple.dock autohide -bool true;ok

running 'Remove delay for showing the dock when in full screen'
defaults write com.apple.dock autohide-fullscreen-delayed -bool false;ok

running 'Setting dock tilezie to 60 pixels'
defaults write com.apple.dock tilesize -int 60;ok

running 'Remove all default app icons from the dock'
defaults write com.apple.dock persistent-apps -array "";ok

running 'Disable dashboard'
defaults write com.apple.dashboard mcx-disabled -bool true;ok

running "Don't show dashboard as a space"
defaults write com.apple.dock dashboard-in-overlay -bool true;ok

running 'Disable automatically arranging applications based on recent use'
defaults write com.apple.dock mru-spaces -bool false;ok

running 'Make dock icons of hidden applications translucent'
defaults write com.apple.dock showhidden -bool true;ok

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

bot 'Safari & Webkit'

running 'Enable safaris debug menu'
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true;ok

running 'Enable develop menu and web inspector in safari'
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true;ok

running 'Prevent time machine from prompting to use new hard drives as backup volumes'
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true;ok

###############################################################################
# Activity Monitor                                                            #
###############################################################################

running 'Show main window when launching activity monitor'
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true;ok

running 'Visualize CPU usage in the activity monitor dock icon'
defaults write com.apple.ActivityMonitor IconType -int 5;ok

running 'Show all processes in activity monitor'
defaults write com.apple.ActivityMonitor ShowCategory -int 0;ok

running 'Sort activity monitor results by CPU usage'
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0;ok

###############################################################################
# Messages                                                                    #
###############################################################################

bot 'Messages'

running 'Disable smart quotes for messages that contain code'
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false;ok

running 'Disable continuous spell checking'
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false;ok