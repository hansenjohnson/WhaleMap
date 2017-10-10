# process and save dfo plane tracklines from 2017

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2017_dfo_tracks/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate)
library(rgdal)
source('functions/config_data.R')

# prepare loop
dfo_track_list = list.files(data_dir, '*.gpx', full.names = T)
DFO = list()

# read files
for(i in seq_along(dfo_track_list)){
  
  # read in file
  tmp = readOGR(dsn = dfo_track_list[i], layer="track_points", verbose = F)
  
  # convert to data frame
  tmp = as.data.frame(tmp)
  
  # select and rename important columns
  tmp = data.frame(tmp$time, tmp$coords.x1, tmp$coords.x2)
  colnames(tmp) = c('time', 'lon', 'lat')
  
  # add to list
  DFO[[i]] = tmp
}

# catch error
if(length(DFO)!=length(dfo_track_list)){stop('Not all tracks were processed!')}

# flatten list
tracks = do.call(rbind, DFO)

# wrangle time
tracks$time = strtrim(tracks$time, 19) # remove unused characters (miliseconds)
tracks$time = as.POSIXct(tracks$time, format = '%Y/%m/%d %H:%M:%S', tz = 'UTC')
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
