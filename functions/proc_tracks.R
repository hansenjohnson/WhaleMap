## proc_tracks ##
# process all trackline data

# libraries
library(plyr)

# functions
source('functions/config_data.R')

# list track files
tracks_list = list.files('data/interim', pattern = 'tracks', full.names = T)

# read in files
TRACKS = list()
for(i in seq_along(tracks_list)){
  TRACKS[[i]] = readRDS(tracks_list[[i]])
}

# merge files
tracks = join_all(TRACKS, type = 'full')

# remove duplicates
tracks = tracks[which(!duplicated(tracks)),]

# adjust column types
# tracks = config_tracks(tracks)

# save
saveRDS(tracks, 'data/processed/tracks.rds')