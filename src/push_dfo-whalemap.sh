#!/bin/bash
# push data to DFO whalemap

# Extract OS name
unamestr=`uname`

# Define OS-specific paths
if [[ "$unamestr" == 'Linux' ]]; then
	
	# Move to project directory
	cd /srv/shiny-server/WhaleMap

	# Write dfo data
	Rscript R/write_dfo-whalemap_data.R

	# copy output data back to Google Drive
	rclone copy "shared/dfo-whalemap/" whalemapdata:"WhaleMapData_Exchange/"

elif [[ "$unamestr" == 'Darwin' ]]; then

	# Move to project directory
	cd /Users/hansenjohnson/Projects/WhaleMap

	# touch
	touch shared/dfo-whalemap/obs_for_dfo.csv
	touch shared/dfo-whalemap/trk_for_dfo.csv

	echo "Note: will only process and send data to DFO-WhaleMap from server"	
fi
