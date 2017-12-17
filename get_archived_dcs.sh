#!/bin/bash
# download archived LFDCS data detections, then process using R script

# Select app directory
DESTDIR=/srv/shiny-server/WhaleMap # server
#DESTDIR=/Users/hansenjohnson/Projects/WhaleMap # local

# initiate array
declare -A URL

# assign paths to detection data for each deployment
URL=(		
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
