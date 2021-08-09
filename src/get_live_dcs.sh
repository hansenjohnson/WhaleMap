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
	[2021-07-27_buoy_njatl]=http://dcs.whoi.edu/njatl0721/njatl0721_njatl_html/ptracks/manual_analysis.csv
	[2021-07-29_buoy_mamv]=http://dcs.whoi.edu/mamv0721/mamv0721_mamv_html/ptracks/manual_analysis.csv
	[2021-07-19_slocum_scotia]=http://dcs.whoi.edu/dal0721/dal0721_scotia_html/ptracks/manual_analysis.csv
  	[2021-07-06_slocum_cabot]=http://dcs.whoi.edu/dal0721/dal0721_cabot_html/ptracks/manual_analysis.csv
  	[2021-05-27_buoy_mdoc]=http://dcs.whoi.edu/mdoc0521/mdoc0521_mdoc_html/ptracks/manual_analysis.csv
  	[2021-05-25_buoy_nybse]=http://dcs.whoi.edu/nybse0521/nybse0521_nybse_html/ptracks/manual_analysis.csv
  	[2021-05-25_buoy_nybnw]=http://dcs.whoi.edu/nybnw0521/nybnw0521_nybnw_html/ptracks/manual_analysis.csv
	[2021-03-25_slocum_we15]=http://dcs.whoi.edu/cox0321/cox0321_we15_html/ptracks/manual_analysis.csv
	[2021-03-17_slocum_we16]=http://dcs.whoi.edu/sbnms0321/sbnms0321_we16_html/ptracks/manual_analysis.csv	
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
