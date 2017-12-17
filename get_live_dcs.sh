#!/bin/bash
# download live LFDCS detections, then process using R script

# Select app directory
DESTDIR=/srv/shiny-server/WhaleMap # server
#DESTDIR=/Users/hansenjohnson/Projects/WhaleMap # local

# initiate array
declare -A URL

# assign paths to detection data for each deployment
URL=(
	# live		
	[2017-12-16_slocum_otn200]=http://dcs.whoi.edu/dal1217/dal1217_otn200_html/ptracks/manual_analysis.csv
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
( cd ${DESTDIR}; Rscript -e "source('update_live_dcs.R')" )
