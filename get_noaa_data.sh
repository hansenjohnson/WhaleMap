#!/bin/bash
# download survey data from remote repository

## Get data ##

# Move to project data directory
# cd ~/Projects/WhaleMap/data/raw/ # local
cd /srv/shiny-server/WhaleMap/data/raw/ # server

# Make backup directory
mkdir -p backups

# Sync NOAA 2017 aerial data Google drive
# rclone sync drive:"RW Flights - Canada/2017/Flights/" "2017_noaa_twin_otter/" --drive-formats csv --backup-dir backups -v

# Sync NOAA 2018 aerial data Google drive
rclone sync drive:"RW Flights - Canada/2018/Flights/" "2018_noaa_twin_otter/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.mp4

## Update map ##

# cd ~/Projects/WhaleMap/ # local
cd /srv/shiny-server/WhaleMap/ # server
make
