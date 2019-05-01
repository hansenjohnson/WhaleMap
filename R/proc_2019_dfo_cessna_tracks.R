## proc_2019_dfo_cessna_tracks ##
# Process gps data from DFO cessna survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2019_whalemapdata/DFO_cessna/'

# output file name
ofile = '2019_dfo_cessna_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tools))

# functions
source('R/functions.R')

# plot tracks?
plot_tracks = !on_server()

# list files to process
flist = list.files(data_dir, pattern = '.gpx', full.names = T, recursive = T, ignore.case = T)

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
    
    # add metadata
    tracks$date = as.Date(tracks$time)
    tracks$yday = yday(tracks$date)
    tracks$year = year(tracks$date)
    tracks$platform = 'plane'
    tracks$name = 'dfo_cessna'
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
