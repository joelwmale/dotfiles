#!/bin/sh

dockutil --no-restart --remove all
dockutil --no-restart --add "/Applications/Forklift.app"
dockutil --no-restart --add "/Applications/Brave Browser.app"
dockutil --no-restart --add "/Applications/Fantastical.app"

killall Dock