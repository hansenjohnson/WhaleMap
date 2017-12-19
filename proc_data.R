# process all data for use in app

# setup -------------------------------------------------------------------

# functions
source('functions/config_data.R')

# create data directories
interim_dir = 'data/interim'; if(!dir.exists(interim_dir)) dir.create(interim_dir)
proc_dir = 'data/processed'; if(!dir.exists(proc_dir)) dir.create(proc_dir)

# interim data ------------------------------------------------------------

# all narwc (historical tracks and sightings 1951 - 2015)
source('functions/proc_narwc.R')

# all dcs (gliders, buoys, etc tracks and detections)
source('functions/proc_archived_dcs.R')
source('functions/proc_live_dcs.R')
source('functions/proc_dcs_latest_position.R')

# 2016 shelagh (vessel) tracks
source('functions/proc_shelagh_2016.R')

# 2017 aerial survey tracks
source('functions/proc_noaa_twin_otter.R')
source('functions/proc_dfo_twin_otter.R')
source('functions/proc_tc_dash8.R')

# 2017 shelagh (vessel) tracks
source('functions/proc_shelagh_tracks_2017.R')

# 2017 sightings
source('functions/proc_sightings_2017.R')

# processed data ----------------------------------------------------------

source('functions/proc_map_polygons.R')
source('functions/proc_sonobuoys.R')
source('functions/proc_observations.R')
source('functions/proc_tracks.R')
