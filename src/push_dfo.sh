#!/bin/bash
# push summary data back to google drive

# Extract OS name
unamestr=`uname`

# Define OS-specific paths
if [[ "$unamestr" == 'Linux' ]]; then
	DESTDIR=/srv/shiny-server/WhaleMap # server
	SSHDIR=/home/hansen
elif [[ "$unamestr" == 'Darwin' ]]; then
	DESTDIR=/Users/hansenjohnson/Projects/WhaleMap # local
	SSHDIR=/Users/hansenjohnson
fi

# Move to project directory
cd ${DESTDIR}

# Write output data
Rscript R/write_dfo_data.R

# Write summary reports
Rscript R/write_dfo_summary.R

# copy output data back to Google Drive
rclone copy "shared/dfo/" whalemapdata:"WhaleMapData_Processed/"
