#!/bin/bash
# download survey data from remote repository

## Get data ##

# Move to project data directory
# cd ~/Projects/WhaleMap/data/raw/ # local
cd /srv/shiny-server/WhaleMap/data/raw/ # server

# Make backup directory
mkdir -p backups

# Sync Canadian aerial data Google drive
rclone sync whalemapdata:"WhaleMapData_Master/" "2018_whalemapdata/" --drive-formats csv --backup-dir backups -v --exclude *.JPG

## Update map ##

# cd ~/Projects/WhaleMap/ # local
cd /srv/shiny-server/WhaleMap/ # server
make
