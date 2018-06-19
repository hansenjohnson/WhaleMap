#!/bin/bash
# push summary data back to google drive

# Move to project parent directory
# cd ~/Projects/WhaleMap # local
cd /srv/shiny-server/WhaleMap/ # server

# Build output data
Rscript functions/build_output_data.R

# copy output data with Google Drive
rclone copy "output/" whalemapdata:"WhaleMapData_Processed/"
