#!/bin/bash
# push summary data back to google drive

# Move to project parent directory
# cd ~/Projects/WhaleMap # local
cd /srv/shiny-server/WhaleMap/ # server

# Write output data
Rscript functions/write_output_data.R

# Write summary reports
Rscript functions/write_summary_reports.R

# copy output data back to Google Drive
rclone copy "output/" whalemapdata:"WhaleMapData_Processed/"
