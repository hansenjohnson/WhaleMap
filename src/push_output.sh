#!/bin/bash
# push summary data back to google drive

# Move to project parent directory
# cd ~/Projects/WhaleMap # local
cd /srv/shiny-server/WhaleMap/ # server

# Write output data
Rscript R/write_output_data.R

# Write summary reports
Rscript R/write_summary_reports.R

# copy output data back to Google Drive
rclone copy "shared/dfo/" whalemapdata:"WhaleMapData_Processed/"
