#!/bin/sh

bot 'cloning repositories'

CODE=$HOME/Code

# create an list of repositories to clone
sites=(
    "joelmale.com"
    "careerlane"
    "pingwire" 
    "uniform-exchange"
)

# loop through the list and clone each repository
for site in "${sites[@]}"
do
    action "cloning $site"
    git clone git@github.com:joelwmale/$site.git $CODE/$site > /dev/null 2>&1;ok

    action "configuring $site"
    cd $CODE/$site
    composer install > /dev/null 2>&1;ok
    npm install > /dev/null 2>&1;ok
done