#!/bin/bash
# download survey data from remote repository

## Get data ##

# Move to project data directory
# cd ~/Projects/WhaleMap/data/raw/ # local
cd /srv/shiny-server/WhaleMap/data/raw/ # server

# Make backup directory
mkdir -p backups

# Sync NEAq 2018 vessel data Dropbox
rclone sync dropbox:"NEAq_CWI Effort_2018" "2018_neaq_nereid/" --backup-dir backups -v --exclude *.JPG --exclude *.mp4

## Update map ##

# cd ~/Projects/WhaleMap/ # local
cd /srv/shiny-server/WhaleMap/ # server
make
