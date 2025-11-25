#!/bin/bash
# push data to DFO whalemap

# get hostname
HOSTNAME=`hostname`

# Define OS-specific paths
if [[ "$HOSTNAME" == 'AZE-WHALEMAP1' ]]; then
	
	# Move to project directory
	cd /srv/shiny-server/WhaleMap

	# Write data
	Rscript R/share_sarbo.R

	# copy output data back to Google Drive
	rclone copy "shared/sarbo/" wm_drive:"SARBO_Zone_Map/" --drive-shared-with-me

elif [[ "$HOSTNAME" != 'AZE-WHALEMAP1' ]]; then

	# Move to project directory
	cd /Users/${USER}/Projects/WhaleMap

# Write data
	Rscript R/share_sarbo.R

	echo "Note: will only send data to SARBO from server"	
fi
