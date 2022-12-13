#!/bin/bash
# process map data from BOEM

# Define OS-specific paths
if [[ "$hostname" == 'AZE-WHALEMAP1' ]]; then
	DESTDIR=/srv/shiny-server/WhaleMap # server
	SSHDIR=/home/wmpadmin
elif [[ "$hostname" != 'AZE-WHALEMAP1' ]]; then
  DESTDIR=/Users/${USER}/Projects/WhaleMap # local
	SSHDIR=/Users/${USER}
fi

# move to project directory
cd ${DESTDIR}

# process BOEM data
Rscript R/map_boem.R

# restart app
touch restart.txt