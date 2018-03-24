## dfo_twin_otter ##
# Process gps data from DFO Twin Otter survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/dfo_twin_otter_tracks/'

# output directory
output_dir = 'data/interim/'

# plot tracks?
plot_tracks = F

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
library(rgdal, quietly = T, warn.conflicts = F)
library(tools, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')
source('functions/subsample_gps.R')
source('functions/plot_save_track.R')

# list files to process
flist = list.files(data_dir, pattern = '.gpx', full.names = T)

# remove known problem files from list
flist = flist[-which(basename(flist) == '20171007_corr.gpx')]
flist = flist[-which(basename(flist) == '20171007.gpx')]

# specify column names
cnames = c('time', 'lon', 'lat', 'speed', 'altitude')

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in file
  tmp = readOGR(dsn = flist[i], layer="track_points", verbose = F)
  
  # convert to data frame
  tmp = as.data.frame(tmp)
  
  # dummy variable for speed
  tmp$speed = NA
  
  # select and rename important columns
  tmp = data.frame(tmp$time, tmp$coords.x1, tmp$coords.x2, tmp$speed, tmp$ele)
  colnames(tmp) = cnames
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%Y/%m/%d %H:%M:%OS', tz = 'UTC')
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'plane'
  tracks$name = 'dfo'
  tracks$id = paste0(tracks$date, '_plane_dfo')
  
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
saveRDS(tracks, paste0(output_dir, 'dfo_twin_otter_tracks.rds'))
