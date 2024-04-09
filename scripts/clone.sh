#!/bin/sh

bot 'cloning repositories'

CODE=$HOME/Code

# create an list of repositories to clone
personalSites=(
    "joelmale.com"
    "pingwire" 
)

pixelSites=(
    "careerlane"
    "wearepixel.com.au"
)

# loop through the list and clone each repository
for site in "${personalSites[@]}"
do
    action "cloning $site"
    git clone git@github.com:joelwmale/$site.git $CODE/$site > /dev/null 2>&1;ok

    action "configuring $site"
    cd $CODE/$site
    composer install > /dev/null 2>&1
    npm install > /dev/null 2>&1;ok
done

for site in "${pixelSites[@]}"
do
    action "cloning $site"
    git clone git@github.com:wearepixel/$site.git $CODE/$site > /dev/null 2>&1;ok

    action "configuring $site"
    cd $CODE/$site
    composer install > /dev/null 2>&1
    npm install > /dev/null 2>&1;ok
done