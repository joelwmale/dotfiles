#!/usr/bin/env bash
# macOS preferences. Each group asks first, so nothing changes without a yes.
# Pruned against macOS 26 behaviour: dead keys, Safari (sandboxed), universalaccess (TCC-blocked)
# and security-lowering tweaks were dropped. Keys that moved to -currentHost use it below.
# Not verified on macOS 27: a key can be accepted and silently ignored, so check System Settings.

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$ROOT/helpers.sh"

bot 'macOS preferences'

if [ "$DRY_RUN" != 1 ]; then
    osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1
fi

write() { run defaults write "$@"; }

if ask 'Typing: no smart quotes, dashes, auto-capitalise or auto-correct; fast key repeat?' Y; then
    write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false
    write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    write NSGlobalDomain KeyRepeat -int 2
    write NSGlobalDomain InitialKeyRepeat -int 15
    write NSGlobalDomain AppleKeyboardUIMode -int 3
    ok
fi

if ask 'Windows and dialogs: expanded save/print panels, save to disk, no window restore?' Y; then
    write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
    write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
    write NSGlobalDomain NSDisableAutomaticTermination -bool true
    write NSGlobalDomain NSWindowResizeTime -float 0.001
    write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
    write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
    write com.apple.CrashReporter DialogType -string none
    write NSGlobalDomain com.apple.sound.beep.feedback -int 0
    ok
fi

if ask 'Developer: web inspector in WebKit and Electron apps, plain-text TextEdit?' Y; then
    write NSGlobalDomain WebKitDeveloperExtras -bool true
    write com.apple.TextEdit RichText -int 0
    write com.apple.TextEdit NSShowAppCentricOpenPanelInsteadOfUntitledFile -bool false
    ok
fi

if ask 'Finder: hidden files, extensions, path and status bars, list view, no warnings?' Y; then
    write NSGlobalDomain AppleShowAllExtensions -bool true
    write NSGlobalDomain AppleShowScrollBars -string Always
    write com.apple.finder AppleShowAllFiles -bool true
    write com.apple.finder ShowPathbar -bool true
    write com.apple.finder ShowStatusBar -bool true
    write com.apple.finder _FXShowPosixPathInTitle -bool true
    write com.apple.finder _FXSortFoldersFirst -bool true
    write com.apple.finder FXPreferredViewStyle -string Nlsv
    write com.apple.finder FXDefaultSearchScope -string SCcf
    write com.apple.finder FXEnableExtensionChangeWarning -bool false
    write com.apple.finder WarnOnEmptyTrash -bool false
    write com.apple.finder QuitMenuItem -bool true
    write com.apple.finder NewWindowTarget -string PfHm
    write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
    write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true
    write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    write com.apple.desktopservices DSDontWriteUSBStores -bool true
    run chflags nohidden "$HOME/Library"
    ok
fi

if ask 'Screenshots: save PNGs to ~/Screenshots, no shadow, no thumbnail?' Y; then
    run mkdir -p "$HOME/Screenshots"
    write com.apple.screencapture location -string "$HOME/Screenshots"
    write com.apple.screencapture type -string png
    write com.apple.screencapture include-date -bool true
    write com.apple.screencapture disable-shadow -bool true
    write com.apple.screencapture show-thumbnail -bool false
    ok
fi

if ask 'Dock and Mission Control: auto-hide, no bounce, no recents, faster animations?' Y; then
    write com.apple.dock autohide -bool true
    write com.apple.dock autohide-delay -float 0
    write com.apple.dock autohide-time-modifier -float 0.5
    write com.apple.dock autohide-fullscreen-delayed -bool false
    write com.apple.dock no-bouncing -bool true
    write com.apple.dock show-recents -bool false
    write com.apple.dock minimize-to-application -bool true
    write com.apple.dock showhidden -bool true
    write com.apple.dock tilesize -int 60
    write com.apple.dock mru-spaces -bool false
    write com.apple.dock expose-animation-duration -float 0.1
    write com.apple.WindowManager GloballyEnabled -bool false
    ok
fi

if ask 'Menu bar: battery percentage, Bluetooth, clock as "Sat 8 Nov 14:05"?' Y; then
    run defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
    run defaults -currentHost write com.apple.controlcenter Bluetooth -int 18
    write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm"
    ok
fi

if ask 'Security: ask for the password immediately after sleep, no Handoff, no Siri?' Y; then
    write com.apple.screensaver askForPassword -int 1
    write com.apple.screensaver askForPasswordDelay -int 0
    run defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
    run defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false
    write com.apple.assistant.support "Assistant Enabled" -bool false
    write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
    write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    ok
fi

if ask 'Trackpad: scroll direction like a mouse (natural scrolling off)?' N; then
    write NSGlobalDomain com.apple.swipescrolldirection -bool false
    ok
fi

if ask 'Activity Monitor, Time Machine and Photos tweaks?' Y; then
    write com.apple.ActivityMonitor OpenMainWindow -bool true
    write com.apple.ActivityMonitor IconType -int 5
    write com.apple.ActivityMonitor ShowCategory -int 0
    write com.apple.ActivityMonitor SortColumn -string CPUUsage
    write com.apple.ActivityMonitor SortDirection -int 0
    write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
    run defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
    ok
fi

if ask 'Do not sleep while on power (long builds)?' N; then
    run sudo pmset -c sleep 0
    ok
fi

if [ "$DRY_RUN" != 1 ]; then
    for app in Dock Finder SystemUIServer; do
        killall "$app" >/dev/null 2>&1
    done
fi

bot 'Preferences applied. Some need a logout or restart.'
