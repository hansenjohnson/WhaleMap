# process and save dfo plane tracklines from 2017

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2017_dfo_tracks/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate)
library(plotKML)
source('functions/config_data.R')

# prepare loop
dfo_track_list = list.files(data_dir, '*.gpx', full.names = T)
DFO = list()

# read files
for(i in seq_along(dfo_track_list)){
  
  # read in file
  tmp = readGPX(dfo_track_list[i])$tracks
  
  # convert to data frame
  tmp = tmp[[1]]; tmp = tmp[[1]] # unsure why this needs to be run twice...
  
  # remove unused column
  tmp$ele = NULL
  
  # add to list
  DFO[[i]] = tmp
}

# catch error
if(length(DFO)!=length(dfo_track_list)){stop('Not all tracks were processed!')}

# flatten list
tracks = do.call(rbind, DFO)

# wrangle time
tracks$time = as.POSIXct(tracks$time, format = '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
tracks$date = as.Date(tracks$time)
tracks$yday = yday(tracks$time)
tracks$year = year(tracks$time)

# add deployment metadata
tracks$platform = 'plane'
tracks$name = 'dfo'
tracks$id = paste0(tracks$date, '_plane_dfo')

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, '2017_dfo_tracks.rds'))
