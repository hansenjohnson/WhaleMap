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
	[2022-02-15_slocum_ru34]=http://dcs.whoi.edu/rutgers0222/rutgers0222_ru34_html/ptracks/manual_analysis.csv
	[2022-02-11_slocum_we16]=http://dcs.whoi.edu/cox0222/cox0222_we16_html/ptracks/manual_analysis.csv
	[2022-01-13_slocum_ru34]=http://dcs.whoi.edu/rutgers0122/rutgers0122_ru34_html/ptracks/manual_analysis.csv
	[2021-12-15_slocum_we03]=http://dcs.whoi.edu/gom1221/gom1221_we03_html/ptracks/manual_analysis.csv
	[2021-12-10_slocum_we14]=http://dcs.whoi.edu/sbnms1221/sbnms1221_we14_html/ptracks/manual_analysis.csv
	[2021-12-05_slocum_um_240]=http://dcs.whoi.edu/um1221/um1221_um_240_html/ptracks/manual_analysis.csv
	[2021-11-20_slocum_ru34]=http://dcs.whoi.edu/rutgers1121/rutgers1121_ru34_html/ptracks/manual_analysis.csv
	[2021-11-05_slocum_we16]=http://dcs.whoi.edu/cox1121/cox1121_we16_html/ptracks/manual_analysis.csv
	[2021-10-28_buoy_ncch]=http://dcs.whoi.edu/ncch1021/ncch1021_ncch_html/ptracks/manual_analysis.csv
	[2021-10-19_slocum_qala1]=http://dcs.whoi.edu/dal1021/dal1021_qala1_html/ptracks/manual_analysis.csv	
	[2021-07-27_buoy_njatl]=http://dcs.whoi.edu/njatl0721/njatl0721_njatl_html/ptracks/manual_analysis.csv
	[2021-07-29_buoy_mamv]=http://dcs.whoi.edu/mamv0721/mamv0721_mamv_html/ptracks/manual_analysis.csv
  	[2021-05-27_buoy_mdoc]=http://dcs.whoi.edu/mdoc0521/mdoc0521_mdoc_html/ptracks/manual_analysis.csv
  	[2021-05-25_buoy_nybse]=http://dcs.whoi.edu/nybse0521/nybse0521_nybse_html/ptracks/manual_analysis.csv
  	[2021-05-25_buoy_nybnw]=http://dcs.whoi.edu/nybnw0521/nybnw0521_nybnw_html/ptracks/manual_analysis.csv	
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
