#!/bin/bash
# download SAS map data

# Extract project paths
. ./src/get_paths.sh

# define data directory
DATADIR=${DESTDIR}/data/raw/sas/

# define URL
. ./src/get_sas_url.sh

# make data directory
mkdir -p ${DATADIR}

# download sas data
wget -N ${URL} -P ${DATADIR}
