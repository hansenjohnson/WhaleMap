#!/bin/bash
# download survey data from remote repository

## Get data ##

# Move to project data directory
# cd ~/Projects/WhaleMap/data/raw/ # local
cd /srv/shiny-server/WhaleMap/data/raw/ # server

# Make backup directory
mkdir -p backups

# Sightings
rclone sync whalemapdata:2018 Opportunistic Sightings/2018_narw_opportunistic_sightings/ --drive-formats csv --backup-dir backups -v

## Update map ##

# cd ~/Projects/WhaleMap/ # local
cd /srv/shiny-server/WhaleMap/ # server
make
