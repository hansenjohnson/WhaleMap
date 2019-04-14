#!/bin/bash
# download SAS map data

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

# define data directory
DATADIR=${DESTDIR}/data/raw/sas/

# define URL
. ./src/get_sas_url.sh

# make data directory
mkdir -p ${DATADIR}

# download sas data
wget -N ${URL} -P ${DATADIR}
