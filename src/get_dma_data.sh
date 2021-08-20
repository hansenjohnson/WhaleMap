#!/bin/bash
# download US DMA data

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

# move to project directory
cd ${DESTDIR}

# define data directory
DATADIR=${DESTDIR}/data/raw/dma/

# define url
# URL=https://fish.nefsc.noaa.gov/cgi-bin/mammalmaps/xmlgenDMA.pl
URL=https://apps-nefsc.fisheries.noaa.gov/cgi-bin/mammalmaps/xmlgenDMA.pl

# make data directory
mkdir -p ${DATADIR}

# download sas data
wget -N ${URL} -P ${DATADIR}

# process
Rscript R/proc_dma.R
make
