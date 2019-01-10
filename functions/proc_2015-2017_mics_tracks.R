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
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
suppressPackageStartupMessages(library(readxl))

# functions
source('functions/config_data.R')
source('functions/subsample_gps.R')
source('functions/plot_save_track.R')
source('functions/on_server.R')

# plot tracks?
plot_tracks = !on_server()

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

# combine and save --------------------------------------------------------

# combine all flights
TRACKS = do.call(rbind, TRK)

# config flight data
tracks = config_tracks(TRACKS)

# remove inappropriate points from 2017 (likely waypoint layer)
tracks = tracks[!tracks$id %in% c('2017-07-27_vessel_mics_mistral', '2017-07-05_vessel_mics_rafale'),]

# save
saveRDS(tracks, paste0(output_dir, ofile))
