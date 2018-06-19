#!/bin/bash
# push summary data back to google drive

# Move to project parent directory
# cd ~/Projects/WhaleMap # local
cd /srv/shiny-server/WhaleMap/ # server

# Build output data
Rscript functions/build_output_data.R

# sync output data with Google Drive
rclone sync "output/" whalemapdata:"WhaleMapData_Processed/"
