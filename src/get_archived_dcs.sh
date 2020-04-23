#!/bin/bash
# download archived LFDCS data detections, then process using R script

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
	[2020-03-06_slocum_we04]=http://dcs.whoi.edu/sbnms0320/sbnms0320_we04_html/ptracks/manual_analysis.csv
	[2019-12-17_slocum_we03]=http://dcs.whoi.edu/gom1219/gom1219_we03_html/ptracks/manual_analysis.csv
	[2019-12-21_slocum_we16]=http://dcs.whoi.edu/cox1219/cox1219_we16_html/ptracks/manual_analysis.csv
  	[2020-01-30_slocum_we14]=http://dcs.whoi.edu/hatteras0120/hatteras0120_we14_html/ptracks/manual_analysis.csv
	[2020-02-05_slocum_we15]=http://dcs.whoi.edu/hatteras0120/hatteras0120_we15_html/ptracks/manual_analysis.csv
  	[2020-01-14_slocum_we04]=http://dcs.whoi.edu/sbnms0120/sbnms0120_we04_html/ptracks/manual_analysis.csv
  	[2019-02-20_buoy_nybight]=http://dcs.whoi.edu/nyb0219/nyb0219_buoy_html/ptracks/manual_analysis.csv
	[2019-09-25_slocum_scotia]=http://dcs.whoi.edu/dal0919/dal0919_scotia_html/ptracks/manual_analysis.csv  
	[2019-09-04_slocum_capx638]=http://dcs.whoi.edu/twr0919/twr0919_capx638_html/ptracks/manual_analysis.csv
	[2019-08-10_slocum_dal556]=http://dcs.whoi.edu/dal0819/dal0819_dal556_html/ptracks/manual_analysis.csv
	[2019-08-28_slocum_bond]=http://dcs.whoi.edu/dal0819/dal0819_bond_html/ptracks/manual_analysis.csv
  	[2019-06-05_slocum_scotia]=http://dcs.whoi.edu/dal0619/dal0619_scotia_html/ptracks/manual_analysis.csv
	[2019-07-24_slocum_bond]=http://dcs.whoi.edu/dal0719/dal0719_bond_html/ptracks/manual_analysis.csv
	[2019-06-04_slocum_fundy]=http://dcs.whoi.edu/dal0619/dal0619_fundy_html/ptracks/manual_analysis.csv
	[2019-03-13_slocum_scotia]=http://dcs.whoi.edu/dal0319/dal0319_scotia_html/ptracks/manual_analysis.csv
	[2019-01-23_slocum_we15]=http://dcs.whoi.edu/hatteras0119/hatteras0119_we15_html/ptracks/manual_analysis.csv
	[2019-01-22_slocum_we14]=http://dcs.whoi.edu/hatteras0119/hatteras0119_we14_html/ptracks/manual_analysis.csv
	[2018-12-01_slocum_we03]=http://dcs.whoi.edu/gom1218/gom1218_we03_html/ptracks/manual_analysis.csv
	[2018-02-13_buoy_nybight]=http://dcs.whoi.edu/nyb0218/nyb0218_buoy_html/ptracks/manual_analysis.csv
	[2018-10-04_buoy_mdr]=http://dcs.whoi.edu/mdr1018/mdr1018_buoy_html/ptracks/manual_analysis.csv
	[2018-11-13_slocum_scotia]=http://dcs.whoi.edu/dal1118/dal1118_scotia_html/ptracks/manual_analysis.csv
	[2018-10-23_slocum_dal556]=http://dcs.whoi.edu/dal1018/dal1018_dal556_html/ptracks/manual_analysis.csv
	[2018-11-01_slocum_otn200]=http://dcs.whoi.edu/dal1118/dal1118_otn200_html/ptracks/manual_analysis.csv
	[2018-09-13_slocum_fundy]=http://dcs.whoi.edu/dal0918/dal0918_fundy_html/ptracks/manual_analysis.csv
	[2018-06-10_slocum_dal556]=http://dcs.whoi.edu/dal0618/dal0618_dal556_html/ptracks/manual_analysis.csv
	[2018-09-18_slocum_otn200]=http://dcs.whoi.edu/dal0918/dal0918_otn200_html/ptracks/manual_analysis.csv
	[2018-07-19_slocum_scotia]=http://dcs.whoi.edu/dal0718/dal0718_scotia_html/ptracks/manual_analysis.csv
	[2018-08-15_slocum_otn200]=http://dcs.whoi.edu/dal0818/dal0818_otn200_html/ptracks/manual_analysis.csv
	[2018-06-09_slocum_fundy]=http://dcs.whoi.edu/dal0618/dal0618_fundy_html/ptracks/manual_analysis.csv
	[2018-02-22_slocum_we03]=http://dcs.whoi.edu/hatteras0218/hatteras0218_we03_html/ptracks/manual_analysis.csv
	[2016-06-23_buoy_nybight]=http://dcs.whoi.edu/nyb0616/dmon009_html/ptracks/manual_analysis.csv
	[2017-08-02_slocum_otn200]=http://dcs.whoi.edu/dal0817/dal0817_otn200_html/ptracks/manual_analysis.csv
	[2017-10-03_slocum_dal556]=http://dcs.whoi.edu/dal1017/dal1017_dal556_html/ptracks/manual_analysis.csv
	[2016-09-28_buoy_nomans]=http://dcs.whoi.edu/nomans0916/dmon028_html/ptracks/manual_analysis.csv
	[2017-06-23_wave_crispusattucks]=http://dcs.whoi.edu/gom0717/gom0717_crispusattucks_html/ptracks/manual_analysis.csv
	[2017-06-05_slocum_dal556]=http://dcs.whoi.edu/dal0617_dal556/dal556_html/ptracks/manual_analysis.csv
	[2017-06-02_slocum_bond]=http://dcs.whoi.edu/dal0617_bond/bond_html/ptracks/manual_analysis.csv
	[2017-02-28_slocum_we03]=http://dcs.whoi.edu/nomans0217/we03_html/ptracks/manual_analysis.csv
	[2016-11-02_slocum_otn200]=http://dcs.whoi.edu/dal1116_otn200/otn200_html/ptracks/manual_analysis.csv
	[2016-10-06_slocum_dal556]=http://dcs.whoi.edu/dal1016_dal556/dal556_html/ptracks/manual_analysis.csv
	[2016-09-23_slocum_we03]=http://dcs.whoi.edu/mdr0916/we03_html/ptracks/manual_analysis.csv
	[2016-07-24_slocum_otn201]=http://dcs.whoi.edu/dal0716_otn201/otn201_html/ptracks/manual_analysis.csv
	[2016-06-24_slocum_otn200]=http://dcs.whoi.edu/dal0616_otn200/otn200_html/ptracks/manual_analysis.csv
	[2016-06-24_buoy_mdr]=http://dcs.whoi.edu/mdr0616/dmon011_html/ptracks/manual_analysis.csv
	[2016-04-13_slocum_we03]=http://dcs.whoi.edu/gsc0416/we03_html/ptracks/manual_analysis.csv
	[2016-03-30_slocum_we03]=http://dcs.whoi.edu/gsc0316/we03_html/ptracks/manual_analysis.csv
	[2015-03-24_buoy_nomans]=http://dcs.whoi.edu/nomans0315/dmon008_html/ptracks/manual_analysis.csv
	[2015-09-05_buoy_mdr]=http://dcs.whoi.edu/mdr0915/dmon010_html/ptracks/manual_analysis.csv
	[2015-09-14_slocum_dal556]=http://dcs.whoi.edu/rb0915_dal556/dal556_html/ptracks/manual_analysis.csv
	[2015-10-27_slocum_otn200]=http://dcs.whoi.edu/rb1015_otn200/otn200_html/ptracks/manual_analysis.csv
	[2015-09-10_slocum_otn200]=http://dcs.whoi.edu/rb0915_otn200/otn200_html/ptracks/manual_analysis.csv
	[2015-07-28_slocum_we04]=http://dcs.whoi.edu/rb0715_whoi/we04_html/ptracks/manual_analysis.csv
	[2015-07-27_slocum_otn200]=http://dcs.whoi.edu/rb0715_otn/otn200_html/ptracks/manual_analysis.csv
	[2015-04-11_slocum_we03]=http://dcs.whoi.edu/gsc0415/we03_html/ptracks/manual_analysis.csv
	[2014-09-02_slocum_we10]=http://dcs.whoi.edu/rb0914/we10_html/ptracks/manual_analysis.csv
)

# download data
for i in "${!URL[@]}"; do

	# define data directory
	DATADIR=${DESTDIR}/data/raw/dcs/archived/${i}

	# make data directory
	mkdir -p ${DATADIR}

	# download glider detections
	wget -q -N ${URL[$i]} -P ${DATADIR}

done

# process data
# ( cd ${DESTDIR}; Rscript -e "source('proc_archived_dcs.R')" )
