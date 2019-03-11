#!/bin/bash
# sync with JASCO server, then process with R script

# Define user directory
SSHDIR=/Users/hansenjohnson

# Select app directory
# DESTDIR=/srv/shiny-server/WhaleMap # server
DESTDIR=/Users/hansenjohnson/Projects/WhaleMap # local

# define data directory
DATADIR=${DESTDIR}/data/raw/jasco/

# make data directory
mkdir -p ${DATADIR}

# sync data
rsync -e "ssh -i ${SSHDIR}/.ssh/mykey" whalemap@142.176.15.238:/home/whalemap/*.csv ${DATADIR}
