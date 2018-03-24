#!/bin/bash
# download survey data from remote repository

# Move to project data directory
cd ~/Projects/WhaleMap/data/raw/ # local
# cd /srv/shiny-server/WhaleMap/data/raw/ # server

# Make backup directory
mkdir -p backups

# Sightings
rclone sync drive:2018-narw-opportunistic-sightings/ 2018_opportunistic_sightings/ --drive-formats csv --backup-dir backups --no-update-modtime -v
