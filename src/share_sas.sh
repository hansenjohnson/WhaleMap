#!/bin/bash
# download SAS map data

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

# define data directory
DATADIR=${DESTDIR}/data/raw/sas/

# define URL
. ./src/sas_url.sh

# make data directory
mkdir -p ${DATADIR}

# download sas data
wget -N ${URL} -P ${DATADIR}

# process
Rscript R/share_sas.R
make