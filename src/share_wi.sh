#!/bin/bash
# push data to DFO whalemap

# get hostname
HOSTNAME=`hostname`

# Define OS-specific paths
if [[ "$HOSTNAME" == 'AZE-WHALEMAP1' ]]; then
	
	# Move to project directory
	cd /srv/shiny-server/WhaleMap

	# Write dfo data
	Rscript R/share_wi.R

	# copy output data back to Google Drive
	rclone copy "shared/dfo-whalemap/" whalemapdata:"WhaleMapData_Exchange/"

elif [[ "$HOSTNAME" != 'AZE-WHALEMAP1' ]]; then

	# Move to project directory
	cd /Users/${USER}/Projects/WhaleMap

	# touch
	touch shared/dfo-whalemap/obs_for_dfo.csv
	touch shared/dfo-whalemap/trk_for_dfo.csv

	echo "Note: will only process and send data to DFO-WhaleMap from server"	
fi
