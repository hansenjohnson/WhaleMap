#!/bin/bash
# process map data from BOEM

# Extract OS name
unamestr=`uname`

# Define OS-specific paths
if [[ "$USER" == 'wmpadmin' ]]; then
	DESTDIR=/srv/shiny-server/WhaleMap # server
	SSHDIR=/home/wmpadmin
elif [[ "$USER" != 'wmpadmin' ]]; then
    DESTDIR=/Users/${USER}/Projects/WhaleMap # local
	SSHDIR=/Users/${USER}
fi

# move to project directory
cd ${DESTDIR}

# process BOEM data
Rscript R/map_boem.R

# restart app
touch restart.txt