## proc_tracks ##
# combine all trackline data

# functions
source('functions/config_data.R')

# list track files
tracks_list = list.files('data/interim', pattern = 'tracks', full.names = T)

# read in files
for(i in seq_along(tracks_list)){

  # get data
  itrack = readRDS(tracks_list[[i]])
  # itrack = config_tracks(itrack)

  if(i==1){
    tracks = itrack
  }

  # add to list
  tracks = rbind(tracks, itrack)
}

# remove duplicates
tracks = tracks[which(!duplicated(tracks)),]

# save
saveRDS(tracks, 'data/processed/tracks.rds')
