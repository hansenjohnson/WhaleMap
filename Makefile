
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
														data/interim/dcs_archived_tracks.rds \
														data/interim/dcs_live_tracks.rds
	Rscript $<

# historical Canadian NARWC data
data/interim/narwc_tracks.rds : functions/proc_narwc.R data/raw/narwc/*
	Rscript $<

# 2016 shelagh tracks
data/interim/2016_shelagh_tracks.rds : functions/proc_2016_shelagh.R data/raw/2016_shelagh/*
	Rscript $<

# 2017 shelagh tracks
data/interim/2017_shelagh_tracks.rds : functions/proc_2017_shelagh_tracks.R data/raw/2017_shelagh_tracks/*
	Rscript $<

# 2017 DFO twin otter tracks
data/interim/2017_dfo_twin_otter_tracks.rds : functions/proc_2017_dfo_twin_otter_tracks.R data/raw/2017_dfo_twin_otter_tracks/*
	Rscript $<

# 2017 NOAA twin otter tracks
data/interim/2017_noaa_twin_otter_tracks.rds : functions/proc_2017_noaa_twin_otter_tracks.R data/raw/2017_noaa_twin_otter_tracks/*
	Rscript $<

# 2017 TC dash 8 tracks
data/interim/2017_tc_dash8_tracks.rds : functions/proc_2017_tc_dash8_tracks.R data/raw/2017_tc_dash8_tracks/*
	Rscript $<

# 2018 DFO twin otter tracks
data/interim/2018_dfo_twin_otter_tracks.rds : functions/proc_2018_dfo_twin_otter_tracks.R data/raw/2018_dfo_twin_otter_tracks/*
	Rscript $<

# DCS archived tracks
data/interim/dcs_archived_tracks.rds : functions/proc_archived_dcs.R data/raw/dcs/archived/*/*
	Rscript $<

# DCS live tracks
data/interim/dcs_live_tracks.rds : functions/proc_live_dcs.R data/raw/dcs/live/*/*
	Rscript $<

## OBSERVATIONS ##
.PHONY : obs
obs : data/processed/observations.rds

# Combine all sightings
data/processed/observations.rds : functions/proc_observations.R \
																	data/interim/narwc_sightings.rds \
																	data/interim/2016_shelagh_sightings.rds \
																	data/interim/2017_*_sightings.rds \
																	data/interim/2018_opportunistic_sightings.rds \
																	data/interim/dcs_archived_detections.rds \
																	data/interim/dcs_live_detections.rds
	Rscript $<

# historical Canadian NARWC sightings
data/interim/narwc_sightings.rds : functions/proc_narwc.R data/raw/narwc/*
	Rscript $<

# 2016 shelagh sightings
data/interim/2016_shelagh_sightings.rds : functions/proc_2016_shelagh.R data/raw/2016_shelagh/*
	Rscript $<

# 2017 sightings
data/interim/2017_*_sightings.rds : functions/proc_2017_sightings.R data/raw/2017_sightings/*
	Rscript $<

# 2018 opportunistic sightings
data/interim/2018_opportunistic_sightings.rds : functions/proc_2018_opportunistic.R data/raw/2018_whalemapdata/2018_opportunistic_sightings/*
	Rscript $<

# DCS archived detections
data/interim/dcs_archived_detections.rds : functions/proc_archived_dcs.R data/raw/dcs/archived/*
	Rscript $<

# DCS live detections
data/interim/dcs_live_detections.rds : functions/proc_live_dcs.R data/raw/dcs/live/*
	Rscript $<

## SONOBUOYS ##
.PHONY : sono
sono : data/processed/sonobuoys.rds

# Combine all sonobuoys
data/processed/sonobuoys.rds : 	functions/proc_sonobuoys.R \
																data/interim/2017_sonobuoys.rds
	Rscript $<

# 2017 sonobuoys
data/interim/2017_sonobuoys.rds : functions/proc_2017_sonobuoys.R data/raw/2017_sonobuoys/*
	Rscript $<

# 2018 sonobuoys
# FILL IN HERE #

## DCS latest positions ##
.PHONY : latest
latest : data/processed/dcs_live_latest_position.rds

# Process dcs positions
data/processed/dcs_live_latest_position.rds : functions/proc_dcs_latest_position.R data/interim/dcs_live_tracks.rds
	Rscript $<

## SHIPPING LANES ##
.PHONY : tss
tss : data/processed/tss.rda

# Process tss
data/processed/tss.rda : functions/proc_tss.R data/raw/tss/*
	Rscript $<

## MPA ##
.PHONY : mpa
tss : data/processed/mpa.rds

# Process mpa
data/processed/mpa.rds : functions/proc_mpa.R data/raw/mpa/*
	Rscript $<

## MAP ##
.PHONY : map
map : ../server_index/whale_map.html

# Build map
../server_index/whale_map.html : functions/build_static_map.R data/processed/*
	Rscript $<

## CLEAN ##
.PHONY : clean
clean :
	rm -f data/interim/*.*
	rm -f data/processed/*.*
