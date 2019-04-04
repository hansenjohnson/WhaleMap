#!/bin/bash
# push summary data back to google drive

# Extract project paths
. ./src/get_paths.sh

# Move to project directory
cd ${DESTDIR}

# Write output data
Rscript R/write_output_data.R

# Write summary reports
Rscript R/write_summary_reports.R

# copy output data back to Google Drive
rclone copy "shared/dfo/" whalemapdata:"WhaleMapData_Processed/"
