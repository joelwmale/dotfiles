#!/bin/sh

dockutil --no-restart --remove all
dockutil --no-restart --add "/Applications/Forklift.app"
dockutil --no-restart --add "/Applications/Brave Browser.app"
dockutil --no-restart --add "/Applications/Fantastical.app"
dockutil --no-restart --add "/Applications/Hyper.app"
dockutil --no-restart --add "/Applications/Spark.app"
dockutil --no-restart --add "/Applications/Things3.app"
dockutil --no-restart --add "/Applications/Visual Studio Code.app"

killall Dock