# process live data and merge with processed data

# functions ---------------------------------------------------------------

source('functions/config_data.R')

# process live data --------------------------------------------------------

source('functions/proc_live_dcs.R')

# read in data ------------------------------------------------------------

# observations
obs = readRDS('data/processed/observations.rds')
obs_live = readRDS('data/interim/dcs_live_detections.rds')

# tracks
tracks = readRDS('data/processed/tracks.rds')
tracks_live = readRDS('data/interim/dcs_live_tracks.rds')

# merge and save obs ------------------------------------------------------

# combine observations
obs_merged = rbind.data.frame(obs, obs_live)

# remove duplicates
obs = obs_merged[which(!duplicated(obs_merged)),]

# save
saveRDS(obs, file = 'data/processed/observations.rds')

# merge and save tracks ---------------------------------------------------

# combine tracks
tracks_merged = rbind.data.frame(tracks, tracks_live)

# remove duplicates
tracks = tracks_merged[which(!duplicated(tracks_merged)),]

# save
saveRDS(tracks, file = 'data/processed/tracks.rds')
