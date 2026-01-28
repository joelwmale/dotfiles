#!/usr/bin/env bash

# ask for the administrator password upfront
sudo -v

# keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

bot 'General ui/ux'

running 'Show battery percentage'
defaults write com.apple.menuextra.battery ShowPercent YES;ok

running 'Disable sound effects on boot'
sudo nvram SystemAudioVolume=" ";ok

running 'Disable audio feedback when volume is changed'
defaults write com.apple.sound.beep.feedback -bool false;ok

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

running 'Disable crash reporter'
defaults write com.apple.CrashReporter DialogType -string "none";ok

# NOTE: Notification Center cannot be disabled via launchctl in modern macOS (SIP protected)

running 'Restart computer automatically if it freezes'
sudo systemsetup -setrestartfreeze on;ok

###############################################################################
# Modern macOS Performance                                                    #
###############################################################################

bot 'Performance tweaks'

running 'Disable hibernation (handled by APFS on M-series Macs)'
sudo pmset -a hibernatemode 0;ok

# NOTE: Sudden motion sensor doesn't exist on M-series Macs

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

bot 'Configuring trackpad, mouse, keyboard, bluetooth accessories and input';

running 'Increase sound quality for bluetooth headphones/headsets'
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40;ok

running 'Full keyboard access for all controls'
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3;ok

running 'Set language and text formats'
defaults write NSGlobalDomain AppleLanguages -array 'en'
defaults write NSGlobalDomain AppleLocale -string 'en_AU@currency=AUD'
defaults write NSGlobalDomain AppleMeasurementUnits -string 'Centimeters'
defaults write NSGlobalDomain AppleMetricUnits -bool true;ok

running 'Set timezone to Australia/Brisbane'
systemsetup -settimezone 'Australia/Brisbane' > /dev/null;ok

running 'Disable automatic capitalization as it’s annoying when typing code'
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false;ok

running 'Disable smart dashes as they’re annoying when typing code'
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false;ok

running 'Disable automatic period substitution as it’s annoying when typing code'
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false;ok

running 'Disable smart quotes as they’re annoying when typing code'
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false;ok

running 'Disable auto-correct'
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false;ok

running 'Disable natural scrolling'
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false;ok

running 'Enable press-and-hold for accented characters'
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false;ok

running 'Set fast keyboard repeat rate'
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15;ok

# NOTE: iTunes removed in macOS Catalina, replaced by Music/TV/Podcasts

running 'Turn off keyboard illumination when computer is not used for 5 minutes'
defaults write com.apple.BezelServices kDimTime -int 300;ok

running 'Right click with 2 fingers'
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -int 1;ok

###############################################################################
# Spotlight                                                                      #
###############################################################################

bot 'Configuring spotlight'

# NOTE: Cannot disable Spotlight indexing in modern macOS (SIP protected)

running 'Disable Spotlight web search results'
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true;ok

###############################################################################
# Screen                                                                      #
###############################################################################

bot 'Configuring screen settings'

running 'Require password immediately after sleep or screen saver'
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0;ok

running 'Create Screenshots folder'
mkdir -p "${HOME}/Screenshots";ok

running 'Save screenshots to ~/Screenshots'
defaults write com.apple.screencapture location -string "${HOME}/Screenshots";ok

running 'Include date in screenshot filenames'
defaults write com.apple.screencapture include-date -bool true;ok

running 'Save screenshots as png'
defaults write com.apple.screencapture type -string "png";ok

running 'Disable shadow in screenshots'
defaults write com.apple.screencapture disable-shadow -bool true;ok

running 'Disable screenshot preview thumbnail'
defaults write com.apple.screencapture show-thumbnail -bool false;ok

###############################################################################
# Finder                                                                      #
###############################################################################

bot 'Configuring finder'

running 'Set default finder window ~'
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/";ok

running 'Allow quitting finder via ⌘ + Q'
defaults write com.apple.finder QuitMenuItem -bool true;ok

running 'Show all file extensions'
defaults write NSGlobalDomain AppleShowAllExtensions -bool true;ok

running 'Show hidden files'
defaults write com.apple.finder AppleShowAllFiles -bool true;ok

running 'Show path bar'
defaults write com.apple.finder ShowPathbar -bool true;ok

running 'Show status bar'
defaults write com.apple.finder ShowStatusBar -bool true;ok

running 'Keep folders on top when sorting by name'
defaults write com.apple.finder _FXSortFoldersFirst -bool true;ok

running 'Allow text selection in Quick Look'
defaults write com.apple.finder QLEnableTextSelection -bool true;ok

running 'Show current path as finder title'
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true;ok

running 'Search current folder when searching by default'
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf";ok

running 'Disable warning when changing a file extension'
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false;ok

running 'Disable DS_Store files on network volumes'
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true;ok

running 'Automatically open a new Finder window when a volume is mounted'
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true;ok

running 'Disable disk image verification'
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true;ok

running 'Use list view in all finder windows'
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv";ok

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

running 'Hide recents in dock'
defaults write com.apple.dock show-recents -bool false;ok

running 'Speed up dock show/hide animation'
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5;ok

running 'Minimize windows into application icon'
defaults write com.apple.dock minimize-to-application -bool true;ok

running 'Automatically hide and show the dock'
defaults write com.apple.dock autohide -bool true;ok

running 'Remove delay for showing the dock when in full screen'
defaults write com.apple.dock autohide-fullscreen-delayed -bool false;ok

running 'Setting dock tilesize to 60 pixels'
defaults write com.apple.dock tilesize -int 60;ok

# NOTE: Dashboard was removed in macOS Catalina

running 'Disable Stage Manager by default'
defaults write com.apple.WindowManager GloballyEnabled -bool false;ok

running 'Speed up Mission Control animations'
defaults write com.apple.dock expose-animation-duration -float 0.1;ok

running 'Disable automatically arranging applications based on recent use'
defaults write com.apple.dock mru-spaces -bool false;ok

running 'Make dock icons of hidden applications translucent'
defaults write com.apple.dock showhidden -bool true;ok

running 'Disable transparency in the menu bar and elsewhere'
defaults write com.apple.universalaccess reduceTransparency 0;ok

running 'Set highlight colour to purple'
defaults write NSGlobalDomain AppleHighlightColor -string "0.541176471 0.168627451 0.88627451";ok

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

bot 'Configuring Safari & Webkit'

running 'Enable safaris debug menu'
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true;ok

running 'Enable develop menu and web inspector in safari'
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true;ok

###############################################################################
# Time Machine                                                                #
###############################################################################

bot 'Configuring time machine'

# NOTE: 'tmutil disablelocal' is deprecated in modern macOS

running 'Prevent time machine from prompting to use new hard drives as backup volumes'
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true;ok

###############################################################################
# Activity Monitor                                                            #
###############################################################################

bot 'Changing Activity monitor settings'

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
# App Store                                                                   #
###############################################################################

bot 'Configuring mac app store'

running 'Enable the automatic update check'
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true;ok

running 'Check for software updates daily, not just once per week'
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1;ok

running 'Download newly available updates in background'
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1;ok

running 'Install System data files & security updates'
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1;ok

running 'Enable developer mode for mac app store'
defaults write com.apple.appstore WebKitDeveloperExtras -bool true;ok

###############################################################################
# Messages                                                                    #
###############################################################################

bot 'Configuring Messages app'

running 'Disable smart quotes for messages that contain code'
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false;ok

running 'Disable continuous spell checking'
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false;ok

###############################################################################
# Photos                                                                      #
###############################################################################

bot 'Configuring photos'

running 'Prevent Photos from opening automatically when devices are plugged in'
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true;ok

###############################################################################
# Energy saving                                                               #
###############################################################################

bot 'Updating the Energy saving settings'

running 'Enable lid wakeup'
sudo pmset -a lidwake 1;ok

running 'Disable machine sleep while charging'
sudo pmset -c sleep 0;ok

###############################################################################
# Menu Bar & Control Center                                                   #
###############################################################################

bot 'Configuring menu bar'

running 'Show Bluetooth in menu bar'
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true;ok

running 'Show date and time in menu bar clock'
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm";ok

running 'Show battery percentage in menu bar'
defaults write com.apple.controlcenter BatteryShowPercentage -bool true;ok

###############################################################################
# Developer Settings                                                          #
###############################################################################

bot 'Configuring developer settings'

running 'Show full POSIX path as Finder window title'
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true;ok

running 'Disable press-and-hold for keys (enable key repeat for coding)'
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false;ok

running 'Avoid creating .DS_Store files on network or USB volumes'
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true;ok

###############################################################################
# Privacy & Security                                                          #
###############################################################################

bot 'Configuring privacy settings'

running 'Disable Siri'
defaults write com.apple.assistant.support "Assistant Enabled" -bool false;ok

running 'Disable Siri voice feedback'
defaults write com.apple.assistant.backedup "Use device speaker for TTS" -int 3;ok

###############################################################################
# Continuity & Handoff                                                        #
###############################################################################

bot 'Configuring continuity'

running 'Disable Handoff'
defaults write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
defaults write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false;ok

###############################################################################
# Finish                                                                      #
###############################################################################

bot 'All defaults applied! Some changes require logout/restart to take effect.'