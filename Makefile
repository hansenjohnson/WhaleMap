## DEFINE VARIABLES
report_error = @bash src/report_error.sh $<
remove_error = @bash src/remove_error.sh $<

## ALL ##
.PHONY : all
all : obs latest wi dma map

## OBSERVATIONS ##
.PHONY : obs
obs : data/processed/observations.rds

# Combine all sightings
data/processed/observations.rds : R/combine.R \
									data/interim/ccs_*.rds \
									data/interim/dcs_archived_*.rds \
									data/interim/dcs_live_*.rds \
									data/interim/narwc_*.rds \
									data/interim/neaq_aerial_*.rds \
									data/interim/neaq_sne_*.rds \
									data/interim/nefsc_archived_*.rds \
									data/interim/nefsc_vessel_*.rds \
									data/interim/nerw_*.rds \
									data/interim/serw_*.rds \
									data/interim/sas_obs.rds \
									data/interim/wi_*.rds \
									data/interim/wm_*.rds
	$(report_error)
	Rscript $<
	$(remove_error)

# CCS
data/interim/ccs_*.rds : R/proc_ccs.R data/raw/ccs/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS archived tracks
data/interim/dcs_archived_*.rds : R/proc_archived_dcs.R data/raw/dcs/archived/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS live tracks
data/interim/dcs_live_*.rds : R/proc_live_dcs.R data/raw/dcs/live/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# NARWC
data/interim/narwc_*.rds : R/proc_narwc.R data/raw/narwc/*
	$(report_error)
	Rscript $<
	$(remove_error)

# NEAq aerial
data/interim/neaq_aerial_*.rds : R/proc_neaq_aerial.R data/raw/neaq/aerial/*
	$(report_error)
	Rscript $<
	$(remove_error)

# NEAq SNE
data/interim/neaq_sne_*.rds : R/proc_neaq_sne.R data/raw/neaq/sne/*
	$(report_error)
	Rscript $<
	$(remove_error)

# NEFSC archived
data/interim/nefsc_archived_*.rds : R/proc_nefsc_archived.R data/raw/wm/*
	$(report_error)
	Rscript $<
	$(remove_error)

# NEFSC vessel
data/interim/nefsc_vessel_*.rds : R/proc_nefsc_vessel.R data/raw/nefsc_vessel/*
	$(report_error)
	Rscript $<
	$(remove_error)

# NERW
data/interim/nerw_*.rds : R/proc_nerw.R data/raw/nerw/*
	$(report_error)
	Rscript $<
	$(remove_error)

# SERW
data/interim/serw_*.rds : R/proc_serw.R data/raw/serw/*/*.csv
	$(report_error)
	Rscript $<
	$(remove_error)

# SAS sightings
data/interim/sas_obs.rds : R/share_sas.R data/raw/sas/*
	$(report_error)
	Rscript $<
	$(remove_error)

# WhaleInsight
data/interim/wi_*.rds : R/proc_wi.R data/raw/wi/*
	$(report_error)
	Rscript $<
	$(remove_error)

# WhaleMap (old)
data/interim/wm_*.rds : R/proc_wm.R data/raw/wm/*
	$(report_error)
	Rscript $<
	$(remove_error)

## DCS latest positions ##
.PHONY : latest
latest : data/processed/dcs_live_latest_position.rds

# Process dcs positions
data/processed/dcs_live_latest_position.rds : R/proc_dcs_latest_position.R \
												data/interim/dcs_live_eff.rds
	$(report_error)
	Rscript $<
	$(remove_error)

## WI ##
.PHONY : wi
wi : shared/dfo-whalemap/*.csv

# Share data with DFO
shared/dfo-whalemap/*.csv : src/share_wi.sh R/share_wi.R data/processed/effort.rds data/processed/observations.rds
	src/share_wi.sh

## DMA ##
.PHONY : dma
dma : data/processed/dma.rda

# Process dma
data/processed/dma.rda : R/map_dma.R \
						data/raw/gis/dma/*.pl
	$(report_error)
	Rscript $<
	$(remove_error)

## MAP ##
.PHONY : map
map : ./static_map/whalemap.html

# Build map
./static_map/whale_map_en.html : R/build_static_map.R data/processed/*
	$(report_error)
	Rscript $<
	cp -r static_map/* ../server_index/
	$(remove_error)

## CLEAN ##
.PHONY : clean
clean :
	rm -f data/interim/*.*
	rm -f data/processed/*.*
