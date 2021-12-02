## DEFINE VARIABLES
report_error = @bash src/report_error.sh $<
remove_error = @bash src/remove_error.sh $<

## ALL ##
.PHONY : all
all : tracks obs latest tss gis dfo map

## TRACKS ##
.PHONY : tracks
tracks : data/processed/tracks.rds

# Combine all tracks
data/processed/tracks.rds : R/proc_tracks.R \
														data/interim/nefsc_historical_tracks.rds \
														data/interim/2015-2017_mics_tracks.rds \
														data/interim/2016_shelagh_tracks.rds \
														data/interim/2017_shelagh_tracks.rds \
														data/interim/2017_dfo_twin_otter_tracks.rds \
														data/interim/2017_tc_dash8_tracks.rds \
														data/interim/2018_dfo_twin_otter_tracks.rds \
														data/interim/2018_dfo_partenavia_tracks.rds \
														data/interim/2018_dfo_cessna_tracks.rds \
														data/interim/2018_tc_dash7_tracks.rds \
														data/interim/2018_tc_dash8_tracks.rds \
														data/interim/2018_neaq_nereid_tracks.rds \
														data/interim/2018_cwi_jdmartin_tracks.rds \
														data/interim/2018_mics_tracks.rds \
														data/interim/2018_dfo_cetus_tracks.rds \
														data/interim/2019_noaa_twin_otter_tracks.rds \
														data/interim/2019_dfo_cessna_tracks.rds \
														data/interim/2019_tc_dash8_tracks.rds \
														data/interim/2019_tc_dash7_tracks.rds \
														data/interim/2019_mics_tracks.rds \
														data/interim/2019_neaq_tracks.rds \
														data/interim/2019_dfo_cp_tracks.rds \
														data/interim/2019_dfo_coriolis_tracks.rds \
														data/interim/2019_dfo_twin_otter_tracks.rds \
														data/interim/2020_noaa_twin_otter_tracks.rds \
														data/interim/2020_dfo_cessna_tracks.rds \
														data/interim/2020_dfo_cessna2_tracks.rds \
														data/interim/2020_tc_dash8_tracks.rds \
														data/interim/2020_dfo_twin_otter_tracks.rds \
														data/interim/2020_niha_tracks.rds \
														data/interim/2020_tc_dash7_tracks.rds \
														data/interim/2020_neaq_tracks.rds \
														data/interim/2020_dfo_coriolis_tracks.rds \
														data/interim/2020_dfo_hudson_tracks.rds \
														data/interim/2020_tc_rpas_tracks.rds \
														data/interim/2021_ccs_tracks.rds \
														data/interim/2021_neaq_aerial_tracks.rds \
														data/interim/2021_noaa_twin_otter_tracks.rds \
														data/interim/2021_dfo_cessna_yob_tracks.rds \
														data/interim/2021_tc_dash8_tracks.rds \
														data/interim/2021_dfo_twin_otter_tracks.rds \
														data/interim/2021_dfo_cessna_zwf_tracks.rds \
														data/interim/2021_dfo_cessna_igb_tracks.rds \
														data/interim/2021_tc_dash7_tracks.rds \
														data/interim/2021_dfo_rhib_tracks.rds \
														data/interim/2021_neaq_vessel_tracks.rds \
														data/interim/2021_dfo_hudson_tracks.rds \
														data/interim/2021_mics_tracks.rds \
														data/interim/2021_tc_rpas_tracks.rds \
														data/interim/2021_dfo_viking_tracks.rds \
														data/interim/seus_aerial_tracks.rds \
														data/interim/dcs_archived_tracks.rds \
														data/interim/dcs_live_tracks.rds
	$(report_error)
	Rscript $<
	$(remove_error)

# historical NEFSC tracks
data/interim/nefsc_historical_tracks.rds : R/proc_nefsc_historical.R data/raw/nefsc/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2015-2017 MICS tracks
data/interim/2015-2017_mics_tracks.rds : R/proc_2015-2017_mics_tracks.R data/raw/2015-2017_mics/effort/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2016 shelagh tracks
data/interim/2016_shelagh_tracks.rds : R/proc_2016_shelagh.R data/raw/2016_shelagh/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 shelagh tracks
data/interim/2017_shelagh_tracks.rds : R/proc_2017_shelagh_tracks.R data/raw/2017_shelagh_tracks/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 DFO twin otter tracks
data/interim/2017_dfo_twin_otter_tracks.rds : R/proc_2017_dfo_twin_otter_tracks.R data/raw/2017_dfo_twin_otter_tracks/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 TC dash 8 tracks
data/interim/2017_tc_dash8_tracks.rds : R/proc_2017_tc_dash8_tracks.R data/raw/2017_tc_dash8_tracks/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 DFO twin otter tracks
data/interim/2018_dfo_twin_otter_tracks.rds : R/proc_2018_dfo_twin_otter_tracks.R data/raw/2018_whalemapdata/DFO_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 DFO partenavia tracks
data/interim/2018_dfo_partenavia_tracks.rds : R/proc_2018_dfo_partenavia_tracks.R data/raw/2018_whalemapdata/DFO_partenavia/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 DFO cessna tracks
data/interim/2018_dfo_cessna_tracks.rds : R/proc_2018_dfo_cessna_tracks.R data/raw/2018_whalemapdata/DFO_cessna/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 TC dash7 tracks
data/interim/2018_tc_dash7_tracks.rds : R/proc_2018_tc_dash7_tracks.R data/raw/2018_whalemapdata/TC_dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 TC dash8 tracks
data/interim/2018_tc_dash8_tracks.rds : R/proc_2018_tc_dash8_tracks.R data/raw/2018_whalemapdata/TC_dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 NEAq nereid tracks
data/interim/2018_neaq_nereid_tracks.rds : R/proc_2018_neaq_nereid.R data/raw/2018_neaq_cwi/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 CWI jdmartin tracks
data/interim/2018_cwi_jdmartin_tracks.rds : R/proc_2018_cwi_jdmartin.R data/raw/2018_neaq_cwi/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 MICS tracks
data/interim/2018_mics_tracks.rds : R/proc_2018_mics_tracks.R data/raw/2018_mics_sightings/Effort/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo tag vessel tracks
data/interim/2018_dfo_cetus_tracks.rds : R/proc_2018_dfo_cetus_tracks.R data/raw/2018_whalemapdata/DFO_vessel_cetus/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 NOAA twin otter tracks
data/interim/2019_noaa_twin_otter_tracks.rds : R/proc_2019_noaa_twin_otter.R data/raw/2019_noaa_twin_otter/edit_data/WhaleMap/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 DFO cessna tracks
data/interim/2019_dfo_cessna_tracks.rds : R/proc_2019_dfo_cessna_tracks.R data/raw/2019_whalemapdata/DFO_cessna/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 TC dash8 tracks
data/interim/2019_tc_dash8_tracks.rds : R/proc_2019_tc_dash8_tracks.R data/raw/2019_whalemapdata/TC_Dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 TC dash7 tracks
data/interim/2019_tc_dash7_tracks.rds : R/proc_2019_tc_dash7_tracks.R data/raw/2019_whalemapdata/TC_Dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 MICS tracks
data/interim/2019_mics_tracks.rds : R/proc_2019_mics_tracks.R data/raw/2019_mics/Effort/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 NEAq tracks
data/interim/2019_neaq_tracks.rds : R/proc_2019_neaq.R data/raw/2019_neaq/*.csv
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 DFO C&P tracks
data/interim/2019_dfo_cp_tracks.rds : R/proc_2019_dfo_cp_tracks.R data/raw/2019_whalemapdata/DFO_CP_NARWFlights/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 DFO twin otter tracks
data/interim/2019_dfo_twin_otter_tracks.rds : R/proc_2019_dfo_twin_otter_tracks.R data/raw/2019_whalemapdata/DFO_twin_otter/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 DFO Coriolis
data/interim/2019_dfo_coriolis_tracks.rds : R/proc_2019_dfo_coriolis_tracks.R data/raw/2019_whalemapdata/DFO_Coriolis/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 NOAA twin otter tracks
data/interim/2020_noaa_twin_otter_tracks.rds : R/proc_2020_noaa_twin_otter.R data/raw/2020_noaa_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO cessna tracks
data/interim/2020_dfo_cessna_tracks.rds : R/proc_2020_dfo_cessna_tracks.R data/raw/2020_whalemapdata/DFO_cessna/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO cessna2 tracks
data/interim/2020_dfo_cessna2_tracks.rds : R/proc_2020_dfo_cessna2_tracks.R data/raw/2020_whalemapdata/DFO_Cessna2/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 TC dash8 tracks
data/interim/2020_tc_dash8_tracks.rds : R/proc_2020_tc_dash8_tracks.R data/raw/2020_whalemapdata/TC_Dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO twin otter tracks
data/interim/2020_dfo_twin_otter_tracks.rds : R/proc_2020_dfo_twin_otter_tracks.R data/raw/2020_whalemapdata/DFO_twin_otter/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 Hawkins tracks
data/interim/2020_niha_tracks.rds : R/proc_2020_niha_tracks.R data/raw/2020_niha/Tracks/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 TC dash7 tracks
data/interim/2020_tc_dash7_tracks.rds : R/proc_2020_tc_dash7_tracks.R data/raw/2020_whalemapdata/TC_Dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 NEAq tracks
data/interim/2020_neaq_tracks.rds : R/proc_2020_neaq.R data/raw/2020_neaq/*.csv
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO Coriolis
data/interim/2020_dfo_coriolis_tracks.rds : R/proc_2020_dfo_coriolis_tracks.R data/raw/2020_whalemapdata/DFO_Coriolis/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 TC RPAS
data/interim/2020_tc_rpas_tracks.rds : R/proc_2020_tc_rpas_tracks.R data/raw/2020_whalemapdata/TC_RPAS/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO Hudson
data/interim/2020_dfo_hudson_tracks.rds : R/proc_2020_dfo_hudson_tracks.R data/raw/2020_whalemapdata/DFO_Hudson/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 CCS
data/interim/2021_ccs_tracks.rds : R/proc_2021_ccs.R data/raw/2021_ccs/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 NEAq aerial
data/interim/2021_neaq_aerial_tracks.rds : R/proc_2021_neaq_aerial.R data/raw/2021_neaq_aerial/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 NOAA twin otter tracks
data/interim/2021_noaa_twin_otter_tracks.rds : R/proc_2021_noaa_twin_otter.R data/raw/2021_noaa_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO Cessna YOB tracks
data/interim/2021_dfo_cessna_yob_tracks.rds : R/proc_2021_dfo_cessna_yob_tracks.R data/raw/2021_whalemapdata/DFO_Cessna_YOB/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 TC dash8 tracks
data/interim/2021_tc_dash8_tracks.rds : R/proc_2021_tc_dash8_tracks.R data/raw/2021_whalemapdata/TC_Dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO twin otter tracks
data/interim/2021_dfo_twin_otter_tracks.rds : R/proc_2021_dfo_twin_otter_tracks.R data/raw/2021_whalemapdata/DFO_twin_otter/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO Cessna ZWF tracks
data/interim/2021_dfo_cessna_zwf_tracks.rds : R/proc_2021_dfo_cessna_zwf_tracks.R data/raw/2021_whalemapdata/DFO_Cessna_ZWF/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO Cessna IGB tracks
data/interim/2021_dfo_cessna_igb_tracks.rds : R/proc_2021_dfo_cessna_igb_tracks.R data/raw/2021_whalemapdata/DFO_Cessna_IGB/*
	$(report_error)
	Rscript $<
	$(remove_error)	

# 2021 TC dash7 tracks
data/interim/2021_tc_dash7_tracks.rds : R/proc_2021_tc_dash7_tracks.R data/raw/2021_whalemapdata/TC_Dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO RHIB tracks
data/interim/2021_dfo_rhib_tracks.rds : R/proc_2021_dfo_rhib_tracks.R data/raw/2021_whalemapdata/DFO_RHIB/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 NEAq vessel tracks
data/interim/2021_neaq_vessel_tracks.rds : R/proc_2021_neaq_cwi.R data/raw/2021_neaq_cwi/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO Hudson vessel tracks
data/interim/2021_dfo_hudson_tracks.rds : R/proc_2021_dfo_hudson.R data/raw/2021_whalemapdata/DFO_CCGHudson/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 MICS vessel tracks
data/interim/2021_mics_tracks.rds : R/proc_2021_mics_tracks.R data/raw/2021_mics/Effort/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 TC RPAS
data/interim/2021_tc_rpas_tracks.rds : R/proc_2021_tc_rpas_tracks.R data/raw/2021_whalemapdata/TC_RPAS/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DFO viking tracks
data/interim/2021_dfo_viking_tracks.rds : R/proc_2021_dfo_viking.R
	$(report_error)
	Rscript $<
	$(remove_error)

# SEUS aerial tracks
data/interim/seus_aerial_tracks.rds : R/proc_seus_aerial.R data/raw/seus/*/*
	$(report_error)
	Rscript $<
	$(remove_error)	

# DCS archived tracks
data/interim/dcs_archived_tracks.rds : R/proc_archived_dcs.R data/raw/dcs/archived/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS live tracks
data/interim/dcs_live_tracks.rds : R/proc_live_dcs.R data/raw/dcs/live/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

## OBSERVATIONS ##
.PHONY : obs
obs : data/processed/observations.rds

# Combine all sightings
data/processed/observations.rds : R/proc_observations.R \
																	data/interim/nefsc_historical_sightings.rds \
																	data/interim/2015-2017_mics_sightings.rds \
																	data/interim/2016_shelagh_sightings.rds \
																	data/interim/2017_*_sightings.rds \
																	data/interim/2018_opportunistic_sightings.rds \
																	data/interim/2018_mics_sightings.rds \
																	data/interim/2018_dfo_twin_otter_sightings.rds \
																	data/interim/2018_tc_dash7_sightings.rds \
																	data/interim/2018_tc_dash8_sightings.rds \
																	data/interim/2018_dfo_partenavia_sightings.rds \
																	data/interim/2018_dfo_cessna_sightings.rds \
																	data/interim/2018_neaq_nereid_sightings.rds \
																	data/interim/2018_cwi_jdmartin_sightings.rds \
																	data/interim/2018_dfo_cetus_sightings.rds \
																	data/interim/2019_noaa_twin_otter_sightings.rds \
																	data/interim/2019_opportunistic_sightings.rds \
																	data/interim/2019_dfo_cessna_sightings.rds \
																	data/interim/2019_tc_dash8_sightings.rds \
																	data/interim/2019_tc_dash7_sightings.rds \
																	data/interim/2019_mics_sightings.rds \
																	data/interim/2019_neaq_sightings.rds \
																	data/interim/2019_dfo_coriolis_sightings.rds \
																	data/interim/2020_noaa_twin_otter_sightings.rds \
																	data/interim/2020_dfo_cessna_sightings.rds \
																	data/interim/2020_dfo_cessna2_sightings.rds \
																	data/interim/2020_tc_dash8_sightings.rds \
																	data/interim/2020_dfo_cp_sightings.rds \
																	data/interim/2020_opportunistic_sightings.rds \
																	data/interim/2020_dfo_twin_otter_sightings.rds \
																	data/interim/2020_ccgs_sightings.rds \
																	data/interim/2020_niha_sightings.rds \
																	data/interim/2020_tc_dash7_sightings.rds \
																	data/interim/2020_neaq_sightings.rds \
																	data/interim/2020_dfo_coriolis_sightings.rds \
																	data/interim/unb_sightings.rds \
																	data/interim/2020_dfo_hudson_sightings.rds \
																	data/interim/2021_ccs_sightings.rds \
																	data/interim/2021_neaq_aerial_sightings.rds \
																	data/interim/2021_noaa_twin_otter_sightings.rds \
																	data/interim/2021_dfo_cessna_yob_sightings.rds \
																	data/interim/2021_tc_dash8_sightings.rds \
																	data/interim/2021_dfo_twin_otter_sightings.rds \
																	data/interim/2021_dfo_opportunistic_sightings.rds \
																	data/interim/2021_dfo_cessna_zwf_sightings.rds \
																	data/interim/2021_dfo_cessna_igb_sightings.rds \
																	data/interim/2021_dfo_cp_sightings.rds \
																	data/interim/2021_tc_dash7_sightings.rds \
																	data/interim/2021_dfo_rhib_sightings.rds \
																	data/interim/2021_tc_rpas_sightings.rds \
																	data/interim/2021_mics_sightings.rds \
																	data/interim/2021_neaq_vessel_sightings.rds \
																	data/interim/2021_dfo_hudson_sightings.rds \
																	data/interim/seus_aerial_sightings.rds \
																	data/interim/sas_sightings.rds \
																	data/interim/narwc_sightings.rds \
																	data/interim/2021_dfo_viking_detections.rds \
																	data/interim/dcs_archived_detections.rds \
																	data/interim/dcs_live_detections.rds

	$(report_error)
	Rscript $<
	$(remove_error)

# historical NEFSC sightings
data/interim/nefsc_historical_sightings.rds : R/proc_nefsc_historical.R data/raw/nefsc/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2015-2017 MICS sightings
data/interim/2015-2017_mics_sightings.rds : R/proc_2015-2017_mics_sightings.R data/raw/2015-2017_mics/sightings/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2016 shelagh sightings
data/interim/2016_shelagh_sightings.rds : R/proc_2016_shelagh.R data/raw/2016_shelagh/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2017 sightings
data/interim/2017_*_sightings.rds : R/proc_2017_sightings.R data/raw/2017_sightings/*
	$(report_error)
	Rscript R/proc_2017_sightings.R	
	$(remove_error)

# 2018 opportunistic sightings
data/interim/2018_opportunistic_sightings.rds : R/proc_2018_opportunistic.R data/raw/2018_whalemapdata/2018_opportunistic_sightings/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 MICS sightings
data/interim/2018_mics_sightings.rds : R/proc_2018_mics_sightings.R data/raw/2018_mics_sightings/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo twin otter sightings
data/interim/2018_dfo_twin_otter_sightings.rds : R/proc_2018_dfo_twin_otter_sightings.R data/raw/2018_whalemapdata/DFO_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 tc dash7 sightings
data/interim/2018_tc_dash7_sightings.rds : R/proc_2018_tc_dash7_sightings.R data/raw/2018_whalemapdata/TC_dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 tc dash8 sightings
data/interim/2018_tc_dash8_sightings.rds : R/proc_2018_tc_dash8_sightings.R data/raw/2018_whalemapdata/TC_dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo partenavia sightings
data/interim/2018_dfo_partenavia_sightings.rds : R/proc_2018_dfo_partenavia_sightings.R data/raw/2018_whalemapdata/DFO_partenavia/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo cessna sightings
data/interim/2018_dfo_cessna_sightings.rds : R/proc_2018_dfo_cessna_sightings.R data/raw/2018_whalemapdata/DFO_cessna/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 NEAq nereid sightings
data/interim/2018_neaq_nereid_sightings.rds : R/proc_2018_neaq_nereid.R data/raw/2018_neaq_cwi/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 CWI jdmartin sightings
data/interim/2018_cwi_jdmartin_sightings.rds : R/proc_2018_cwi_jdmartin.R data/raw/2018_neaq_cwi/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2018 dfo tag vessel sightings
data/interim/2018_dfo_cetus_sightings.rds : R/proc_2018_dfo_cetus_sightings.R data/raw/2018_whalemapdata/DFO_vessel_cetus/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 noaa twin otter sightings
data/interim/2019_noaa_twin_otter_sightings.rds : R/proc_2019_noaa_twin_otter.R data/raw/2019_noaa_twin_otter/edit_data/WhaleMap/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 opportunistic sightings
data/interim/2019_opportunistic_sightings.rds : R/proc_2019_opportunistic.R data/raw/2019_whalemapdata/2019-opportunistic-sightings/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 dfo cessna sightings
data/interim/2019_dfo_cessna_sightings.rds : R/proc_2019_dfo_cessna_sightings.R data/raw/2019_whalemapdata/DFO_cessna/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 tc dash8 sightings
data/interim/2019_tc_dash8_sightings.rds : R/proc_2019_tc_dash8_sightings.R data/raw/2019_whalemapdata/TC_Dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 tc dash7 sightings
data/interim/2019_tc_dash7_sightings.rds : R/proc_2019_tc_dash7_sightings.R data/raw/2019_whalemapdata/TC_Dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 MICS sightings
data/interim/2019_mics_sightings.rds : R/proc_2019_mics_sightings.R data/raw/2019_mics/*.xlsx
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 NEAQ sightings
data/interim/2019_neaq_sightings.rds : R/proc_2019_neaq.R data/raw/2019_neaq/*.csv
	$(report_error)
	Rscript $<
	$(remove_error)

# 2019 DFO Corliolis sightings
data/interim/2019_dfo_coriolis_sightings.rds : R/proc_2019_dfo_coriolis_sightings.R data/raw/2019_whalemapdata/DFO_Coriolis/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 noaa twin otter sightings
data/interim/2020_noaa_twin_otter_sightings.rds : R/proc_2020_noaa_twin_otter.R data/raw/2020_noaa_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 dfo cessna sightings
data/interim/2020_dfo_cessna_sightings.rds : R/proc_2020_dfo_cessna_sightings.R data/raw/2020_whalemapdata/DFO_cessna/*
	$(report_error)
	Rscript $<
	$(remove_error)
	
# 2020 dfo cessna2 sightings	
data/interim/2020_dfo_cessna2_sightings.rds : R/proc_2020_dfo_cessna2_sightings.R data/raw/2020_whalemapdata/DFO_Cessna2/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 tc dash8 sightings
data/interim/2020_tc_dash8_sightings.rds : R/proc_2020_tc_dash8_sightings.R data/raw/2020_whalemapdata/TC_Dash8/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 dfo cp sightings
data/interim/2020_dfo_cp_sightings.rds : R/proc_2020_dfo_cp_sightings.R data/raw/2020_whalemapdata/2020-C&P/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 opportunistic sightings
data/interim/2020_opportunistic_sightings.rds : R/proc_2020_opportunistic.R data/raw/2020_whalemapdata/2020-opportunistic-sightings/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO twin otter sightings
data/interim/2020_dfo_twin_otter_sightings.rds : R/proc_2020_dfo_twin_otter_sightings.R data/raw/2020_whalemapdata/DFO_twin_otter/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 coast guard opportunistic sightings
data/interim/2020_ccgs_sightings.rds : R/proc_2020_ccgs_sightings.R data/raw/2020_whalemapdata/2020-CCGS/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 Hawkins sightings
data/interim/2020_niha_sightings.rds : R/proc_2020_niha_sightings.R data/raw/2020_niha/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 tc dash7 sightings
data/interim/2020_tc_dash7_sightings.rds : R/proc_2020_tc_dash7_sightings.R data/raw/2020_whalemapdata/TC_Dash7/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 NEAQ sightings
data/interim/2020_neaq_sightings.rds : R/proc_2020_neaq.R data/raw/2020_neaq/*.csv
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO Corliolis sightings
data/interim/2020_dfo_coriolis_sightings.rds : R/proc_2020_dfo_coriolis_sightings.R data/raw/2020_whalemapdata/DFO_Coriolis/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 UNB sightings
data/interim/unb_sightings.rds : R/proc_unb_sightings.R data/raw/unb/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2020 DFO Hudson sightings
data/interim/2020_dfo_hudson_sightings.rds : R/proc_2020_dfo_hudson_sightings.R data/raw/2020_whalemapdata/DFO_Hudson/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 CCS
data/interim/2021_ccs_sightings.rds : R/proc_2021_ccs.R data/raw/2021_ccs/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 NEAq aerial
data/interim/2021_neaq_aerial_sightings.rds : R/proc_2021_neaq_aerial.R data/raw/2021_neaq_aerial/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 noaa twin otter sightings
data/interim/2021_noaa_twin_otter_sightings.rds : R/proc_2021_noaa_twin_otter.R data/raw/2021_noaa_twin_otter/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO cessna YOB sightings
data/interim/2021_dfo_cessna_yob_sightings.rds : R/proc_2021_dfo_cessna_yob_sightings.R data/raw/2021_whalemapdata/DFO_Cessna_YOB/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 tc dash8 sightings
data/interim/2021_tc_dash8_sightings.rds : R/proc_2021_tc_dash8_sightings.R data/raw/2021_whalemapdata/TC_Dash8/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO twin otter sightings
data/interim/2021_dfo_twin_otter_sightings.rds : R/proc_2021_dfo_twin_otter_sightings.R data/raw/2021_whalemapdata/DFO_twin_otter/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO cessna ZWF sightings
data/interim/2021_dfo_cessna_zwf_sightings.rds : R/proc_2021_dfo_cessna_zwf_sightings.R data/raw/2021_whalemapdata/DFO_Cessna_ZWF/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO cessna IGB sightings
data/interim/2021_dfo_cessna_igb_sightings.rds : R/proc_2021_dfo_cessna_igb_sightings.R data/raw/2021_whalemapdata/DFO_Cessna_IGB/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 dfo opportunistic sightings
data/interim/2021_dfo_opportunistic_sightings.rds : R/proc_2021_dfo_opportunistic.R data/raw/2021_whalemapdata/2021_General_Opportunistic_Sightings/* data/raw/2021_whalemapdata/2021-CCGS_Opportunistic_Sightings/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 dfo cp sightings
data/interim/2021_dfo_cp_sightings.rds : R/proc_2021_dfo_cp_sightings.R data/raw/2021_whalemapdata/2021-DFO\ C&P_Opportunistic_Sightings/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 tc dash7 sightings
data/interim/2021_tc_dash7_sightings.rds : R/proc_2021_tc_dash7_sightings.R data/raw/2021_whalemapdata/TC_Dash7/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO rhib sightings
data/interim/2021_dfo_rhib_sightings.rds : R/proc_2021_dfo_rhib_sightings.R data/raw/2021_whalemapdata/DFO_RHIB/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 NEAq/CWI sightings
data/interim/2021_neaq_vessel_sightings.rds : R/proc_2021_neaq_cwi.R data/raw/2021_neaq_cwi/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 DFO Hudson sightings
data/interim/2021_dfo_hudson_sightings.rds : R/proc_2021_dfo_hudson.R data/raw/2021_whalemapdata/DFO_CCGHudson/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 tc rpas sightings
data/interim/2021_tc_rpas_sightings.rds : R/proc_2021_tc_rpas_sightings.R data/raw/2021_whalemapdata/TC_RPAS/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# 2021 MICS sightings
data/interim/2021_mics_sightings.rds : R/proc_2021_mics_sightings.R data/raw/2021_mics/*.xlsx
	$(report_error)
	Rscript $<
	$(remove_error)

# RWSAS sightings
data/interim/sas_sightings.rds : R/proc_sas.R
	$(report_error)
	Rscript $<
	$(remove_error)

# NARWC sightings
data/interim/narwc_sightings.rds : R/proc_narwc_sightings.R data/raw/narwc/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DFO viking detections
data/interim/2021_dfo_viking_detections.rds : R/proc_2021_dfo_viking.R
	$(report_error)
	Rscript $<
	$(remove_error)

# SEUS aerial sightings
data/interim/seus_aerial_sightings.rds : R/proc_seus_aerial.R data/raw/seus/*/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS archived detections
data/interim/dcs_archived_detections.rds : R/proc_archived_dcs.R data/raw/dcs/archived/*
	$(report_error)
	Rscript $<
	$(remove_error)

# DCS live detections
data/interim/dcs_live_detections.rds : R/proc_live_dcs.R data/raw/dcs/live/*
	$(report_error)
	Rscript $<
	$(remove_error)

## DCS latest positions ##
.PHONY : latest
latest : data/processed/dcs_live_latest_position.rds

# Process dcs positions
data/processed/dcs_live_latest_position.rds : R/proc_dcs_latest_position.R \
																							data/interim/dcs_live_tracks.rds
	$(report_error)
	Rscript $<
	$(remove_error)

## SHIPPING LANES ##
.PHONY : tss
tss : data/processed/tss.rda

# Process tss
data/processed/tss.rda : R/proc_tss.R data/raw/tss/*
	$(report_error)
	Rscript $<
	$(remove_error)

## GIS ##
.PHONY : gis
gis : data/processed/gis.rda R/proc_gis.R

# Process management layers
data/processed/gis.rda : R/proc_gis.R data/raw/2021_whalemapdata/GIS_data/*
	$(report_error)
	Rscript $<
	$(remove_error)

## DFO ##
.PHONY : dfo
dfo : shared/dfo-whalemap/*.csv

# Share data with DFO
shared/dfo-whalemap/*.csv : src/push_dfo-whalemap.sh R/write_dfo-whalemap_data.R data/processed/tracks.rds data/processed/observations.rds
	src/push_dfo-whalemap.sh

## MAP ##
.PHONY : map
map : ./static_map/whale_map_en.html

# Build map
./static_map/whale_map_en.html : R/build_static_map.R data/processed/*.rda data/processed/*.rds
	$(report_error)
	Rscript $<
	cp -r static_map/* ../server_index/
	$(remove_error)

## CLEAN ##
.PHONY : clean
clean :
	rm -f data/interim/*.*
	rm -f data/processed/*.*
