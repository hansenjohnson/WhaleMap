#!/bin/bash
# download live LFDCS detections, then process using R script

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

# initiate array
declare -A URL

# assign paths to detection data for each deployment
URL=(
	# live
	[2018-12-01_slocum_we03]=http://dcs.whoi.edu/gom1218/gom1218_we03_html/ptracks/manual_analysis.csv
	[2018-02-13_buoy_nybight]=http://dcs.whoi.edu/nyb0218/nyb0218_buoy_html/ptracks/manual_analysis.csv
	[2019-01-22_slocum_we14]=http://dcs.whoi.edu/hatteras0119/hatteras0119_we14_html/ptracks/manual_analysis.csv
	[2019-01-23_slocum_we15]=http://dcs.whoi.edu/hatteras0119/hatteras0119_we15_html/ptracks/manual_analysis.csv
)

# download data
for i in "${!URL[@]}"; do

	# define data directory
	DATADIR=${DESTDIR}/data/raw/dcs/live/${i}

	# make data directory
	mkdir -p ${DATADIR}

	# download glider detections
	wget -N ${URL[$i]} -P ${DATADIR}

done
