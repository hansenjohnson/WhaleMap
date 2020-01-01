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
  [2019-12-17_slocum_we03]=http://dcs.whoi.edu/gom1219/gom1219_we03_html/ptracks/manual_analysis.csv
	[2019-12-21_slocum_we16]=http://dcs.whoi.edu/cox1219/cox1219_we16_html/ptracks/manual_analysis.csv
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
