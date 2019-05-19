## proc_2015-2017_mics_tracks ##
# Process track data from MICS survey vessels

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2015-2017_mics/effort/'

# output file name
ofile = '2015-2017_mics_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(readxl))

# functions
source('R/functions.R')

# plot tracks?
plot_tracks = !on_server()

# 2015 --------------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = '.gpx$', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  if(file.size(flist[i])<51200){
    next
  }
  
  # read in file
  tmp = readOGR(dsn = flist[i], layer="track_points", verbose = F)
  
  # convert to data frame
  tmp = as.data.frame(tmp)
  
  # dummy variable for speed
  tmp$speed = NA
  
  # select and rename important columns
  tmp = data.frame(tmp$time, tmp$coords.x1, tmp$coords.x2, tmp$speed, tmp$ele)
  colnames(tmp) = c('time', 'lon', 'lat', 'speed', 'altitude')
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%Y/%m/%d %H:%M:%OS', tz = 'UTC')
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # isolate vessel name
  vname = tolower(strsplit(file_path_sans_ext(basename(flist[i])), '-')[[1]][2])
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'vessel'
  tracks$name = paste0('mics_', vname)
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

# combine all flights
TRACKS = bind_rows(TRK)

# config flight data
t1 = config_tracks(TRACKS)

# 2016-2017 ---------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = '_final.xlsx$', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in file
  tmp = read_excel(flist[i], col_names = FALSE)
  
  # define column names
  colnames(tmp) = c('name', 'lon', 'lat', 'time')
  
  # replace unknown platform
  tmp$name[tmp$name == 'Trail001'] = 'unknown'
  
  # dummy variables for speed and altitude
  tmp$speed = NA
  tmp$altitude = NA
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # order by timestamp AND platform
  tracks = tracks[order(tracks$time, tracks$name),]

  # remove bogus timestamps 
  tracks = tracks[!tracks$time < as.POSIXct('1971-01-01 00:00:00'),]
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'vessel'
  tracks$name = paste0('mics_', tolower(tracks$name))
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

# combine --------------------------------------------------------

# combine all flights
TRACKS = bind_rows(TRK)

# config flight data
tracks = config_tracks(TRACKS)

# remove inappropriate points from 2017 (likely waypoint layer)
t2 = tracks[!tracks$id %in% c('2017-07-27_vessel_mics_mistral', '2017-07-05_vessel_mics_rafale'),]

# merge and save --------------------------------------------------------------------

# merge t1 and t2
tracks = rbind(t1, t2)

# save
saveRDS(tracks, paste0(output_dir, ofile))
