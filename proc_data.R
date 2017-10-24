# process all data for use in app

# functions ---------------------------------------------------------------

source('functions/config_data.R')

# process map data --------------------------------------------------------

source('functions/proc_map_polygons.R')

# process ancillary data --------------------------------------------------------

source('functions/proc_sonobuoys.R')

# process each platform ---------------------------------------------------

# all narwc (historical tracks and sightings 1951 - 2015)
source('functions/proc_narwc.R')

# all dcs (gliders, buoys, etc tracks and detections)
source('functions/proc_archived_dcs.R')
source('functions/proc_live_dcs.R')
source('functions/proc_dcs_latest_position.R')

# # noaa (noaa plane) 2015 (THIS IS DUPLICATED BY NARWC HISTORICAL DATA, SO NOT INCLUDING ANYMORE)
# source('functions/proc_noaa_2015.R')

# 2016 shelagh (vessel) tracks
source('functions/proc_shelagh_2016.R')

# 2017 aerial survey tracks
source('functions/proc_noaa_tracks_2017.R')
source('functions/proc_dfo_tracks_2017.R')

# 2017 shelagh (vessel) tracks
source('functions/proc_shelagh_tracks_2017.R')

# 2017 sightings
source('functions/proc_sightings_2017.R')

# combine and save observations -------------------------------------------

# list sightings files
obs_list = list.files('data/interim', pattern = 'sightings|detections', full.names = T)

# read in files
OBS = list()
for(i in seq_along(obs_list)){
  OBS[[i]] = readRDS(obs_list[[i]])
}

# merge files
obs = Reduce(function(x, y) merge(x, y, all=TRUE), OBS)

# adjust column types
obs = config_observations(obs)

# remove duplicates
obs = obs[which(!duplicated(obs)),]

# save
saveRDS(obs, 'data/processed/observations.rds')

# combine and save tracklines ---------------------------------------------

# list track files
tracks_list = list.files('data/interim', pattern = 'tracks', full.names = T)

# read in files
TRACKS = list()
for(i in seq_along(tracks_list)){
  TRACKS[[i]] = readRDS(tracks_list[[i]])
}

# merge files
tracks = Reduce(function(x, y) merge(x, y, all=TRUE), TRACKS)

# sort by time (important for plotting)
tracks = tracks[order(tracks$id, tracks$time),]

# adjust column types
tracks = config_tracks(tracks)

# remove duplicates
tracks = tracks[which(!duplicated(tracks)),]

# save
saveRDS(tracks, 'data/processed/tracks.rds')
