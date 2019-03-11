## proc_2018_cp_king_air_tracks ##
# Process gps data from C&P King Air survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/CP_king_air/'

# output file name
ofile = '2018_cp_king_air_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
library(measurements, quietly = T)

# functions
source('functions/config_data.R')
source('functions/subsample_gps.R')
source('functions/roundTen.R')
source('functions/plot_save_track.R')
source('functions/on_server.R')

# plot tracks?
plot_tracks = !on_server()

# list files to process
flist = list.files(data_dir, pattern = '*_AircraftTracksList.csv$', full.names = T, recursive = T)

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in file
  tmp = read.csv(flist[i], header=TRUE, stringsAsFactors=FALSE, fileEncoding="latin1")
  
  # select only columns of interest
  tmp = tmp[,1:4]
  
  # rename
  colnames(tmp) = c('time', 'lat', 'lon', 'altitude')
  
  # add speed
  tmp$speed = NA
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%d/%m/%Y %H:%M', origin = '1970-01-01', tz = 'UTC', usetz=TRUE)
  
  # remove columns without timestamp
  tmp = tmp[!is.na(tmp$time),]
  
  # remove columns without lat lon
  tmp = tmp[!is.na(tmp$lat),]
  tmp = tmp[!is.na(tmp$lon),]
  
  # clean lat
  tmp$lat = gsub(pattern = '°', replacement = ' ', x = tmp$lat)
  tmp$lat = gsub(pattern = '\'', replacement = ' ', x = tmp$lat)
  tmp$lat = gsub(pattern = '\"N', replacement = '', x = tmp$lat)
  tmp$lat = trimws(tmp$lat)
  
  # convert lat
  tmp$lat = round(as.numeric(measurements::conv_unit(tmp$lat, from = 'deg_min_sec', to = 'dec_deg')), 5)
  
  # clean lon
  tmp$lon = gsub(pattern = '°', replacement = ' ', x = tmp$lon)
  tmp$lon = gsub(pattern = '\'', replacement = ' ', x = tmp$lon)
  tmp$lon = gsub(pattern = '\"W', replacement = '', x = tmp$lon)
  tmp$lon = trimws(tmp$lon)
  
  # convert lon
  tmp$lon = round(as.numeric(measurements::conv_unit(tmp$lon, from = 'deg_min_sec', to = 'dec_deg'))*-1, 5)
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'plane'
  tracks$name = 'cp_king_air'
  tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
  
  # plot track
  if(plot_tracks){
    plot_save_track(tracks, flist[i])
  }
  
  # add to list
  TRK[[i]] = tracks
  
  # catch null error
  if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
if(length(TRK)!=length(flist)){stop('Not all tracks were processed!')}

# combine all flights
TRACKS = do.call(rbind, TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
