## DEFINE VARIABLES
report_error = @bash report_error.sh $<
remove_error = @bash remove_error.sh $<

## ALL ##
.PHONY : all
all : tracks obs sono latest tss mpa map

## TRACKS ##
.PHONY : tracks
tracks : data/processed/tracks.rds

# Combine all tracks
data/processed/tracks.rds : functions/proc_tracks.R \
														data/interim/narwc_tracks.rds \
														data/interim/2016_shelagh_tracks.rds \
														data/interim/2017_shelagh_tracks.rds \
														data/interim/2017_dfo_twin_otter_tracks.rds \
														data/interim/2017_noaa_twin_otter_tracks.rds \
														data/interim/2017_tc_dash8_tracks.rds \
														data/interim/2018_dfo_twin_otter_tracks.rds \
														data/interim/2018_dfo_partenavia_tracks.rds \
														data/interim/2018_dfo_cessna_tracks.rds \
														data/interim/2018_tc_dash7_tracks.rds \
														data/interim/2018_tc_dash8_tracks.rds \
														data/interim/2018_noaa_twin_otter_tracks.rds \
														data/interim/2018_neaq_nereid_tracks.rds \
														data/interim/dcs_archived_tracks.rds \
														data/interim/dcs_live_tracks.rds
	$(report_error)
	Rscript $<
	$(remove_error)

# historical Canadian NARWC data [add rds to dependency list above!]
data/interim/narwc_tracks.rds : functions/proc_narwc.R data/raw/narwc/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2016 shelagh tracks
data/interim/2016_shelagh_tracks.rds : functions/proc_2016_shelagh.R data/raw/2016_shelagh/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 shelagh tracks
data/interim/2017_shelagh_tracks.rds : functions/proc_2017_shelagh_tracks.R data/raw/2017_shelagh_tracks/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 DFO twin otter tracks
data/interim/2017_dfo_twin_otter_tracks.rds : functions/proc_2017_dfo_twin_otter_tracks.R data/raw/2017_dfo_twin_otter_tracks/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 NOAA twin otter tracks
data/interim/2017_noaa_twin_otter_tracks.rds : functions/proc_2017_noaa_twin_otter_tracks.R data/raw/2017_noaa_twin_otter/edit_data/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 TC dash 8 tracks
data/interim/2017_tc_dash8_tracks.rds : functions/proc_2017_tc_dash8_tracks.R data/raw/2017_tc_dash8_tracks/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 DFO twin otter tracks
data/interim/2018_dfo_twin_otter_tracks.rds : functions/proc_2018_dfo_twin_otter_tracks.R data/raw/2018_whalemapdata/DFO_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 DFO partenavia tracks
data/interim/2018_dfo_partenavia_tracks.rds : functions/proc_2018_dfo_partenavia_tracks.R data/raw/2018_whalemapdata/DFO_partenavia/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 DFO cessna tracks
data/interim/2018_dfo_cessna_tracks.rds : functions/proc_2018_dfo_cessna_tracks.R data/raw/2018_whalemapdata/DFO_cessna/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 TC dash7 tracks
data/interim/2018_tc_dash7_tracks.rds : functions/proc_2018_tc_dash7_tracks.R data/raw/2018_whalemapdata/TC_dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 TC dash8 tracks
data/interim/2018_tc_dash8_tracks.rds : functions/proc_2018_tc_dash8_tracks.R data/raw/2018_whalemapdata/TC_dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# # 2018 CP king air tracks
# data/interim/2018_cp_king_air_tracks.rds : functions/proc_2018_cp_king_air_tracks.R data/raw/2018_whalemapdata/CP_king_air/*
	# $(report_error)
	# Rscript $<
	# $(remove_error)

# 2018 NOAA twin otter tracks
data/interim/2018_noaa_twin_otter_tracks.rds : functions/proc_2018_noaa_twin_otter_tracks.R data/raw/2018_noaa_twin_otter/edit_data/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 NEAq nereid tracks
data/interim/2018_neaq_nereid_tracks.rds : functions/proc_2018_neaq_nereid.R data/raw/2018_neaq_nereid/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS archived tracks
data/interim/dcs_archived_tracks.rds : functions/proc_archived_dcs.R data/raw/dcs/archived/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS live tracks
data/interim/dcs_live_tracks.rds : functions/proc_live_dcs.R data/raw/dcs/live/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

## OBSERVATIONS ##
.PHONY : obs
obs : data/processed/observations.rds

# Combine all sightings
data/processed/observations.rds : functions/proc_observations.R \
																	data/interim/narwc_sightings.rds \
																	data/interim/2016_shelagh_sightings.rds \
																	data/interim/2017_*_sightings.rds \
																	data/interim/2018_opportunistic_sightings.rds \
																	data/interim/2018_dfo_twin_otter_sightings.rds \
																	data/interim/2018_tc_dash7_sightings.rds \
																	data/interim/2018_tc_dash8_sightings.rds \
																	data/interim/2018_dfo_partenavia_sightings.rds \
																	data/interim/2018_noaa_twin_otter_sightings.rds \
																	data/interim/2018_neaq_nereid_sightings.rds \
																	data/interim/dcs_archived_detections.rds \
																	data/interim/dcs_live_detections.rds

# data/interim/2018_dfo_cessna_sightings.rds \

	$(report_error)
	Rscript $<
	$(remove_error)

# historical Canadian NARWC sightings [add rds to dependency list above!]
data/interim/narwc_sightings.rds : functions/proc_narwc.R data/raw/narwc/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2016 shelagh sightings
data/interim/2016_shelagh_sightings.rds : functions/proc_2016_shelagh.R data/raw/2016_shelagh/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 sightings
data/interim/2017_*_sightings.rds : functions/proc_2017_sightings.R data/raw/2017_sightings/* \
																		functions/proc_2017_noaa_twin_otter_sightings.R data/raw/2017_noaa_twin_otter/canada2017_ap.csv
	$(report_error)
	Rscript functions/proc_2017_sightings.R
	Rscript functions/proc_2017_noaa_twin_otter_sightings.R
	$(remove_error)

# 2018 opportunistic sightings
data/interim/2018_opportunistic_sightings.rds : functions/proc_2018_opportunistic.R data/raw/2018_whalemapdata/2018_opportunistic_sightings/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo twin otter sightings
data/interim/2018_dfo_twin_otter_sightings.rds : functions/proc_2018_dfo_twin_otter_sightings.R data/raw/2018_whalemapdata/DFO_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 tc dash7 sightings
data/interim/2018_tc_dash7_sightings.rds : functions/proc_2018_tc_dash7_sightings.R data/raw/2018_whalemapdata/TC_dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 tc dash8 sightings
data/interim/2018_tc_dash8_sightings.rds : functions/proc_2018_tc_dash8_sightings.R data/raw/2018_whalemapdata/TC_dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo partenavia sightings
data/interim/2018_dfo_partenavia_sightings.rds : functions/proc_2018_dfo_partenavia_sightings.R data/raw/2018_whalemapdata/DFO_partenavia/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo cessna sightings
# data/interim/2018_dfo_cessna_sightings.rds : functions/proc_2018_dfo_cessna_sightings.R data/raw/2018_whalemapdata/DFO_cessna/*
# 	$(report_error)
# 	Rscript $<
# 	$(remove_error)

# 2018 noaa twin otter sightings
data/interim/2018_noaa_twin_otter_sightings.rds : functions/proc_2018_noaa_twin_otter_sightings.R data/raw/2018_noaa_twin_otter/edit_data/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 NEAq nereid sightings
data/interim/2018_neaq_nereid_sightings.rds : functions/proc_2018_neaq_nereid.R data/raw/2018_neaq_nereid/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS archived detections
data/interim/dcs_archived_detections.rds : functions/proc_archived_dcs.R data/raw/dcs/archived/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS live detections
data/interim/dcs_live_detections.rds : functions/proc_live_dcs.R data/raw/dcs/live/*
	$(report_error)
	Rscript $<
	$(remove_error)

## SONOBUOYS ##
.PHONY : sono
sono : data/processed/sonobuoys.rds

# Combine all sonobuoys
data/processed/sonobuoys.rds : 	functions/proc_sonobuoys.R \
																data/interim/2017_sonobuoys.rds
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 sonobuoys
data/interim/2017_sonobuoys.rds : functions/proc_2017_sonobuoys.R data/raw/2017_sonobuoys/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 sonobuoys
# FILL IN HERE #

## DCS latest positions ##
.PHONY : latest
latest : data/processed/dcs_live_latest_position.rds

# Process dcs positions
data/processed/dcs_live_latest_position.rds : functions/proc_dcs_latest_position.R data/interim/dcs_live_tracks.rds
	$(report_error)
	Rscript $<
	$(remove_error)

## SHIPPING LANES ##
.PHONY : tss
tss : data/processed/tss.rda

# Process tss
data/processed/tss.rda : functions/proc_tss.R data/raw/tss/*
	$(report_error)
	Rscript $<
	$(remove_error)

## MPA ##
.PHONY : mpa
mpa : data/processed/mpa.rds data/processed/management_areas.rda

# Process mpa
data/processed/mpa.rds : functions/proc_mpa.R data/raw/mpa/*
	$(report_error)
	Rscript $<
	$(remove_error)

# Process management areas
data/processed/management_areas.rda : functions/proc_management_areas.R data/raw/2018_whalemapdata/GIS_Data/*
	$(report_error)
	Rscript $<
	$(remove_error)

## MAP ##
.PHONY : map
map : ../server_index/whale_map_en.html

# Build map
../server_index/whale_map_en.html : functions/build_static_map.R data/processed/*.rda data/processed/*.rds
	$(report_error)
	Rscript $<
	$(remove_error)

## CLEAN ##
.PHONY : clean
clean :
	rm -f data/interim/*.*
	rm -f data/processed/*.*
