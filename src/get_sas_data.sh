#!/bin/bash
# download SAS map data

# Extract OS name
. ./src/get_os_name.sh

# define data directory
DATADIR=${DESTDIR}/data/raw/sas/

# define URL
. ./src/get_sas_url.sh

# make data directory
mkdir -p ${DATADIR}

# download sas data
wget -N ${URL} -P ${DATADIR}
