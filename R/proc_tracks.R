## proc_tracks ##
# combine all trackline data

# functions
source('R/functions.R')

# list track files
tracks_list = list.files('data/interim', pattern = 'tracks', full.names = T)

# read in files
TRK = vector('list', length(tracks_list))
for(ii in seq_along(tracks_list)){
  # get data
  TRK[[ii]] = readRDS(tracks_list[[ii]])
}

# flatten list
tracks = suppressWarnings(bind_rows(TRK))

# remove duplicates
tracks = tracks[which(!duplicated(tracks)),]

# config tracks
tracks = config_tracks(tracks)

# save
saveRDS(tracks, 'data/processed/tracks.rds')
