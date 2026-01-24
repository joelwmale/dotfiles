#!/bin/sh

dockutil --no-restart --remove all
dockutil --no-restart --add "/Applications/Brave Browser.app"
dockutil --no-restart --add "/Applications/Fantastical.app"
dockutil --no-restart --add "/Applications/Hyper.app"
dockutil --no-restart --add "/Applications/Setapp/Spark.app"
dockutil --no-restart --add "/Applications/Things3.app"
dockutil --no-restart --add "/Applications/Cursor.app"
dockutil --no-restart --add "/Applications/Discord.app"
dockutil --no-restart --add "/Applications/Slack.app"

killall Dock