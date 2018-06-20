#!/bin/bash
# download live LFDCS detections, then process using R script

# Select app directory
DESTDIR=/srv/shiny-server/WhaleMap # server
# DESTDIR=/Users/hansenjohnson/Projects/WhaleMap # local

# initiate array
declare -A URL

# assign paths to detection data for each deployment
URL=(
	# live
	[2018-06-10_slocum_dal556]=http://dcs.whoi.edu/dal0618/dal0618_dal556_html/ptracks/manual_analysis.csv
	[2018-06-09_slocum_fundy]=http://dcs.whoi.edu/dal0618/dal0618_fundy_html/ptracks/manual_analysis.csv
	[2018-02-13_buoy_nybight]=http://dcs.whoi.edu/nyb0218/nyb0218_buoy_html/ptracks/manual_analysis.csv
)

# download data
for i in "${!URL[@]}"; do

	# define data directory
	DATADIR=${DESTDIR}/data/raw/dcs/live/${i}

	# make data directory
	mkdir -p ${DATADIR}

	# download glider detections
	wget -q -N ${URL[$i]} -P ${DATADIR}

done

# process data
# ( cd ${DESTDIR}; make )
