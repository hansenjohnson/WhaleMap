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
	
	[2019-07-24_slocum_bond]=http://dcs.whoi.edu/dal0719/dal0719_bond_html/ptracks/manual_analysis.csv	
	[2019-06-05_slocum_scotia]=http://dcs.whoi.edu/dal0619/dal0619_scotia_html/ptracks/manual_analysis.csv	
	[2019-02-20_buoy_nybight]=http://dcs.whoi.edu/nyb0219/nyb0219_buoy_html/ptracks/manual_analysis.csv
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
