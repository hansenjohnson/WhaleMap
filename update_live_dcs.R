# process live data and merge with processed data


# setup -------------------------------------------------------------------

# libraries
library(plyr)

# functions
source('functions/config_data.R')

# process live data --------------------------------------------------------

# process live data
source('functions/proc_live_dcs.R')

# extract latest position
source('functions/proc_dcs_latest_position.R')

# read in data ------------------------------------------------------------

# observations
obs = readRDS('data/processed/observations.rds')
obs_live = readRDS('data/interim/dcs_live_detections.rds')

# tracks
tracks = readRDS('data/processed/tracks.rds')
tracks_live = readRDS('data/interim/dcs_live_tracks.rds')

# merge and save obs ------------------------------------------------------

# remove live
obs = obs[-(obs$id %in% unique(obs_live$id)),]

# combine live and archived observations
obs_merged = join(obs, obs_live, type = 'full')

# remove duplicates (excluding id column to avoid keeping both live and archived)
# obs = obs_merged[which(!duplicated(obs_merged[,c(1:6, 8:12)])),]

# save
saveRDS(obs, file = 'data/processed/observations.rds')

# merge and save tracks ---------------------------------------------------

# remove live
tracks = tracks[-(tracks$id %in% unique(tracks_live$id)),]

# combine tracks
tracks_merged = join(tracks, tracks_live, type = 'full')

# remove duplicates (excluding id column to avoid keeping both live and archived)
# tracks = tracks_merged[which(!duplicated(tracks_merged[,c(1:6, 8:9)])),]

# save
saveRDS(tracks, file = 'data/processed/tracks.rds')
