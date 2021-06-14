#!/bin/bash
# push data to DFO whalemap

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

# Write dfo data
Rscript R/write_dfo-whalemap_data.R

# copy output data back to Google Drive
rclone copy "shared/dfo-whalemap/" whalemapdata:"WhaleMapData_Exchange/"
