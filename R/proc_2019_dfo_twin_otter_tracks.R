## proc_2019_dfo_twin_otter_tracks ##
# Process gps data from DFO twin otter survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2019_whalemapdata/DFO_twin_otter/'

# output file name
ofile = '2019_dfo_twin_otter_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(lubridate))

# functions
source('R/functions.R')

# plot tracks?
plot_tracks = !on_server()

# list files to process
flist = list.files(data_dir, pattern = '(\\d{8}).csv', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read and format data ----------------------------------------------------

if(length(flist!=0)){
  
  # read files
  for(i in seq_along(flist)){
    
    if(file.size(flist[i])<51200){
      next
    }
    
    # read in file
    tmp = read.csv(flist[i])
    
    # dummy variable for speed and altitude
    tmp$speed = NA
    tmp$altitude = NA
    
    # select and rename important columns
    colnames(tmp) = c('lat', 'lon', 'time', 'speed', 'altitude')
    
    # add timestamp
    tmp$time = as.POSIXct(tmp$time, format = '%Y-%m-%dT%H:%M:%S', tz = 'UTC')
    
    # subsample (use default subsample rate)
    tracks = subsample_gps(gps = tmp)
    
    # add metadata
    tracks$date = as.Date(tracks$time)  
    tracks$yday = yday(tracks$date)
    tracks$year = year(tracks$date)
    tracks$platform = 'plane'
    tracks$name = 'dfo_twin_otter'
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
  
  # combine all flights
  TRACKS = bind_rows(TRK)
  
} else {
  
  # assign empty data frame
  TRACKS = data.frame()
}

# combine and save --------------------------------------------------------

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
