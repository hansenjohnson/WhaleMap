#!/bin/bash
# download live LFDCS detections

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
	[2020-09-05_slocum_fundy]=http://dcs.whoi.edu/dal0920/dal0920_fundy_html/ptracks/manual_analysis.csv
	[2020-08-16_slocum_capx638]=http://dcs.whoi.edu/twr0820/twr0820_capx638_html/ptracks/manual_analysis.csv
	[2020-07-31_buoy_mamv]=http://dcs.whoi.edu/mamv0720/mamv0720_mamv_html/ptracks/manual_analysis.csv
	[2020-07-30_buoy_njatl]=http://dcs.whoi.edu/njatl0720/njatl0720_njatl_html/ptracks/manual_analysis.csv
	[2020-07-29_slocum_ru34]=http://dcs.whoi.edu/rutgers0720/rutgers0720_ru34_html/ptracks/manual_analysis.csv	
	[2020-06-02_slocum_we16]=http://dcs.whoi.edu/neocs0620/neocs0620_we16_html/ptracks/manual_analysis.csv
	[2020-01-15_buoy_nybnw]=http://dcs.whoi.edu/nybnw0120/nybnw0120_buoy_html/ptracks/manual_analysis.csv
	[2020-01-15_buoy_nybse]=http://dcs.whoi.edu/nybse0120/nybse0120_buoy_html/ptracks/manual_analysis.csv
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
