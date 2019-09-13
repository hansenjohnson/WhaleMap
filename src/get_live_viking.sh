#!/bin/bash
# download live Viking buoy detections, then process using R script

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

# define start and end dates of query
T0="2019-06-01"
T1=`date +%Y-%m-%d`

# define URL
URL="https://www.ogsl.ca/beluga/biodiversity/occurrenceMeasurements/paginatedOccurrenceMeasurements?%24expand=event%2C+event%2Flocation%2C+event%2FdateFormat%2C+extradata%2C+establishmentMeans&%24filter=event%2FeventDateTime+ge+datetime%27"${T0}"T00%3A42%3A28.000Z%27+and+event%2FeventDateTime+le+datetime%27"${T1}"T23%3A40%3A38.000Z%27+and+event%2Fdataset%2Fcollection%2Fid+in+(29)&%24orderby=&%24skip=0&%24top=100&%24language=en"

# define data directory
DATADIR=${DESTDIR}/data/raw/viking/

# make data directory
mkdir -p ${DATADIR}

# download buoy detections
wget -N ${URL} -O ${DATADIR}live.json
