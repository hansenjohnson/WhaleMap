# process and save tc plane tracklines from 2017
# These data were recorded in different formats over the course of the season. Each format requires special treatment to coerce it to the standard form used here.

# setup -------------------------------------------------------------------

library(lubridate)
library(rgdal)
source('functions/config_data.R')
source('functions/roundTen.R')

# list to hold intermediate data
TC = list()
j = 0 # initialize counter

# directory for output
output_dir = 'data/interim/'

# 2017-08a ----------------------------------------------------------------
j = j+1

# directory to look for files
data_dir = 'data/raw/2017_tc_tracks/2017-08a/'

# prepare loop
track_list = list.files(data_dir, '*.*', full.names = T)
TRK = list()

# read files
for(i in seq_along(track_list)){
  
  # read in file
  tmp = read.csv(track_list[i])
  
  # select and rename important columns
  tmp = data.frame(tmp$Ti, tmp$Lo, tmp$La)
  colnames(tmp) = c('time', 'lon', 'lat')
  
  # Correct for variable precision (or errors) in gps
  f = roundTen(tmp$time)/10^9
  tmp$time = tmp$time/f
  
  # add to list
  TRK[[i]] = tmp
}

# catch error
if(length(TRK)!=length(track_list)){stop('Not all tracks were processed!')}

# flatten list
tracks = do.call(rbind, TRK)

# add timestamp
tracks$time = as.POSIXct(tracks$time, origin = '1970-01-01', tz = 'UTC')

# subsample
norig = nrow(tracks)
n = 5
npoints = norig/n
nsub = round(norig/npoints,0)
# # compare subsample
# t = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points
# plot(tracks$lon, tracks$lat, type = 'l')
# lines(t$lon, t$lat, col = 'blue')
tracks = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points

# add to list
TC[[j]] = tracks

# 2017-08b ----------------------------------------------------------------
j = j+1

# directory to look for files
data_dir = 'data/raw/2017_tc_tracks/2017-08b/'

# prepare loop
track_list = list.files(data_dir, '*.*', full.names = T)
TRK = list()

# read files
for(i in seq_along(track_list)){
  
  # read in file
  tmp = read.csv(track_list[i])
  
  # correct for error in naming of 3rd file
  if(i==3){
    colnames(tmp)[7] = 'Longitude'
  }
  
  # select and rename important columns
  tmp = data.frame(tmp$Date.and.Time, tmp$Longitude, tmp$Latitude)
  colnames(tmp) = c('time', 'lon', 'lat')
  
  # convert factor to character
  tmp$time = as.character(tmp$time)
  
  # add timestamp
  if(i==3){
   tmp$time = as.POSIXct(tmp$time, format = '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
  } else{
    tmp$time = as.POSIXct(tmp$time, format = '%d-%m-%Y %H:%M:%S', tz = 'UTC')
  }
  
  # add to list
  TRK[[i]] = tmp
}

# catch error
if(length(TRK)!=length(track_list)){stop('Not all tracks were processed!')}

# flatten list
tracks = do.call(rbind, TRK)

# subsample
norig = nrow(tracks)
n = 30
npoints = norig/n
nsub = round(norig/npoints,0)
# # compare subsample
# t = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points
# plot(tracks$lon, tracks$lat, type = 'l')
# lines(t$lon, t$lat, col = 'blue')
tracks = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points

# add to list
TC[[j]] = tracks

# 2017-08c ----------------------------------------------------------------
j = j+1

# directory to look for files
data_dir = 'data/raw/2017_tc_tracks/2017-08c/'

# prepare loop
track_list = list.files(data_dir, '*.*', full.names = T)
TRK = list()

# read files
for(i in seq_along(track_list)){
  
  # read in file
  tmp = read.csv(track_list[i])
  
  # select and rename important columns
  tmp = data.frame(tmp$time, tmp$lon, tmp$lat)
  colnames(tmp) = c('time', 'lon', 'lat')
  
  # add to list
  TRK[[i]] = tmp
}

# catch error
if(length(TRK)!=length(track_list)){stop('Not all tracks were processed!')}

# flatten list
tracks = do.call(rbind, TRK)

# add timestamp
tracks$time = as.POSIXct(tracks$time, format = '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')

# subsample
norig = nrow(tracks)
n = 30
npoints = norig/n
nsub = round(norig/npoints,0)
# # compare subsample
# t = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points
# plot(tracks$lon, tracks$lat, type = 'l')
# lines(t$lon, t$lat, col = 'blue')
tracks = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points

# add to list
TC[[j]] = tracks

# 2017-09 ----------------------------------------------------------------
j = j+1

# directory to look for files
data_dir = 'data/raw/2017_tc_tracks/2017-09/'

# prepare loop
track_list = list.files(data_dir, '*.*', full.names = T)
TRK = list()

# read files
for(i in seq_along(track_list)){
  
  # read in file
  tmp = read.csv(track_list[i], skip = 2)
  
  # select and rename important columns
  tmp = data.frame(tmp$Timestamp, tmp$Longitude, tmp$Latitude)
  colnames(tmp) = c('time', 'lon', 'lat')
  
  # Correct for variable precision (or errors) in gps
  f = roundTen(tmp$time)/10^9
  tmp$time = tmp$time/f
  
  # add to list
  TRK[[i]] = tmp
}

# catch error
if(length(TRK)!=length(track_list)){stop('Not all tracks were processed!')}

# flatten list
tracks = do.call(rbind, TRK)

# add timestamp
tracks$time = as.POSIXct(tracks$time, origin = '1970-01-01', tz = 'UTC')

# subsample
norig = nrow(tracks)
n = 30
npoints = norig/n
nsub = round(norig/npoints,0)
# # compare subsample
# t = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points
# plot(tracks$lon, tracks$lat, type = 'l')
# lines(t$lon, t$lat, col = 'blue')
tracks = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points

# add to list
TC[[j]] = tracks

# 2017-final ----------------------------------------------------------------
j = j+1

# directory to look for files
data_dir = 'data/raw/2017_tc_tracks/2017-final/'

# prepare loop
track_list = list.files(data_dir, '*.*', full.names = T)
TRK = list()

# read files
for(i in seq_along(track_list)){
  
  # read in file
  tmp = read.csv(track_list[i], skip = 2)
  
  # select and rename important columns
  tmp = data.frame(tmp$Timestamp, tmp$Longitude, tmp$Latitude)
  colnames(tmp) = c('time', 'lon', 'lat')
  
  # Correct for variable precision (or errors) in gps
  f = roundTen(tmp$time)/10^9
  tmp$time = tmp$time/f
  
  # add to list
  TRK[[i]] = tmp
}

# catch error
if(length(TRK)!=length(track_list)){stop('Not all tracks were processed!')}

# flatten list
tracks = do.call(rbind, TRK)

# add timestamp
tracks$time = as.POSIXct(tracks$time, origin = '1970-01-01', tz = 'UTC')

# subsample
norig = nrow(tracks)
n = 50
npoints = norig/n
nsub = round(norig/npoints,0)
# # compare subsample
# t = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points
# plot(tracks$lon, tracks$lat, type = 'l')
# lines(t$lon, t$lat, col = 'blue')
tracks = tracks[seq(1, nrow(tracks), nsub),] # subset to only plot every n data points

# add to list
TC[[j]] = tracks

# combine all data --------------------------------------------------------

# flatten list
TRACKS = do.call(rbind, TC)

# add time info
TRACKS$date = as.Date(TRACKS$time)
TRACKS$yday = yday(TRACKS$date)
TRACKS$year = year(TRACKS$date)

# add deployment metadata
TRACKS$platform = 'plane'
TRACKS$name = 'tc'
TRACKS$id = paste0(TRACKS$date, '_plane_tc')

# config data types
TRACKS = config_tracks(TRACKS)

# save
saveRDS(TRACKS, paste0(output_dir, '2017_tc_tracks.rds'))
