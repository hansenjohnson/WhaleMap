
## ALL ##
.PHONY : all
all : tracks obs sono tss mpa

## TRACKS ##
.PHONY : tracks
tracks : data/processed/tracks.rds

# Combine all tracks
data/processed/tracks.rds : functions/proc_tracks.R \
														data/interim/2016_shelagh_tracks.rds \
														data/interim/2017_shelagh_tracks.rds \
														data/interim/dcs_archived_tracks.rds \
														data/interim/dcs_live_tracks.rds \
														data/interim/dfo_twin_otter_tracks.rds \
														data/interim/narwc_tracks.rds \
														data/interim/noaa_twin_otter_tracks.rds \
														data/interim/tc_dash8_tracks.rds
	Rscript $<

# 2016 shelagh tracks
data/interim/2016_shelagh_tracks.rds : functions/proc_shelagh_2016.R data/raw/2016_shelagh/*
	Rscript $<

# 2017 shelagh tracks
data/interim/2017_shelagh_tracks.rds : functions/proc_shelagh_tracks_2017.R data/raw/2017_shelagh_tracks/*
	Rscript $<

# DCS archived tracks
data/interim/dcs_archived_tracks.rds : functions/proc_archived_dcs.R data/raw/dcs/archived/*
	Rscript $<

# DCS live tracks
data/interim/dcs_live_tracks.rds : functions/proc_live_dcs.R data/raw/dcs/live/*
	Rscript $<

# Process DFO twin otter tracks
data/interim/dfo_twin_otter_tracks.rds : functions/proc_dfo_twin_otter.R data/raw/dfo_twin_otter_tracks/*
	Rscript $<

# Process historical Canadian NARWC data
data/interim/narwc_tracks.rds : functions/proc_narwc.R data/raw/historical/*
	Rscript $<

# Process NOAA twin otter tracks
data/interim/noaa_twin_otter_tracks.rds : functions/proc_noaa_twin_otter.R data/raw/noaa_twin_otter_tracks/*
	Rscript $<

# Process TC dash 8 tracks
data/interim/tc_dash8_tracks.rds : functions/proc_tc_dash8.R data/raw/tc_dash8_tracks/*
	Rscript $<

## OBSERVATIONS ##
.PHONY : obs
obs : data/processed/observations.rds

# Combine all sightings
data/processed/observations.rds : functions/proc_observations.R \
																	data/interim/2016_shelagh_sightings.rds \
																	data/interim/2017_*_sightings.rds \
																	data/interim/dcs_archived_detections.rds \
																	data/interim/dcs_live_detections.rds \
																	data/interim/narwc_sightings.rds
	Rscript $<

# 2016 shelagh sightings
data/interim/2016_shelagh_sightings.rds : functions/proc_shelagh_2016.R data/raw/2016_shelagh/*
	Rscript $<

# 2017 sightings
data/interim/2017_*_sightings.rds : functions/proc_sightings_2017.R data/raw/2017_sightings/*
	Rscript $<

# DCS archived tracks
data/interim/dcs_archived_detections.rds : functions/proc_archived_dcs.R data/raw/dcs/archived/*
	Rscript $<

# DCS live tracks
data/interim/dcs_live_detections.rds : functions/proc_live_dcs.R data/raw/dcs/live/*
	Rscript $<

# historical Canadian NARWC sightings
data/interim/narwc_sightings.rds : functions/proc_narwc.R data/raw/historical/*
	Rscript $<

## SONOBUOYS ##
.PHONY : sono
sono : data/processed/sonobuoys.rds

# Process sonobuoys
data/processed/sonobuoys.rds : functions/proc_sonobuoys.R data/raw/sonobuoys/*
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

## CLEAN ##
.PHONY : clean
clean :
	rm -f data/interim/*.*
	rm -f data/processed/*.*
