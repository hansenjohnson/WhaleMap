## proc_2018_mics_tracks ##
# Process track data from MICS survey vessels

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_mics_sightings/Effort/'

# output file name
ofile = '2018_mics_vessel_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')
source('functions/subsample_gps.R')
source('functions/plot_save_track.R')
source('functions/on_server.R')

# plot tracks?
plot_tracks = !on_server()

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
TRACKS = do.call(rbind, TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
