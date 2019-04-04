#!/bin/bash
# download live LFDCS detections, then process using R script

# Extract project paths
. ./src/get_paths.sh

# initiate array
declare -A URL

# assign paths to detection data for each deployment
URL=(
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