#!/bin/bash
# update SMA data

# get hostname
HOSTNAME=`hostname`

# Define OS-specific paths
if [[ "$HOSTNAME" == 'AZE-WHALEMAP1'  ]]; then # server

	# Move to project directory (on server)
	cd /srv/shiny-server/WhaleMap

elif [[ "$HOSTNAME" != 'AZE-WHALEMAP1'  ]]; then
	
	# Move to project directory (on personal machine)
	cd ~/Projects/WhaleMap

fi

# update sma data
Rscript R/map_sma.R
