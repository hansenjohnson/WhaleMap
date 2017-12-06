#!/bin/bash
# rclone data from Google Drive

# move to data directory
cd /srv/shiny-server/WhaleMap/data/raw/2017_sightings/

# sync files
rclone sync drive:data/ . --drive-formats csv
