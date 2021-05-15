## proc_2021_tc_dash7_tracks ##
# Process gps data from TC Dash-8 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2021_whalemapdata/TC_Dash7/'

# output file name
ofile = 'data/interim/2021_tc_dash7_tracks.rds'

# setup -------------------------------------------------------------------

# libraries
suppressMessages(library(rgdal))
suppressMessages(library(lubridate))
suppressMessages(library(tools))

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '^(\\d{8})_Dash7_tracklog.*.csv$', full.names = T, recursive = T)

# read and format data ----------------------------------------------------

# read files
if(length(flist)!=0){
  
  # list to hold loop output
  TRK = vector('list', length = length(flist))
  
  
  for(i in seq_along(flist)){
    
    # read in file
    tmp = read.csv(flist[i], skip = 2)
    
    # select and rename important columns
    tmp = data.frame(tmp$Timestamp, tmp$Longitude, tmp$Latitude, tmp$Speed, tmp$Altitude)
    colnames(tmp) = c('time', 'lon', 'lat', 'speed', 'altitude')
    
    # Correct for variable precision (or errors) in gps
    f = roundTen(tmp$time)/10^9
    tmp$time = tmp$time/f
    
    # add timestamp
    tmp$time = as.POSIXct(tmp$time, origin = '1970-01-01', tz = 'UTC', usetz=TRUE)
    
    # remove columns without timestamp
    tmp = tmp[!is.na(tmp$time),]
    
    # remove columns without lat lon
    tmp = tmp[!is.na(tmp$lat),]
    tmp = tmp[!is.na(tmp$lon),]
    
    # subsample (use default subsample rate)
    tracks = subsample_gps(gps = tmp)
    
    # add metadata
    tracks$date = as.Date(tracks$time)
    tracks$yday = yday(tracks$date)
    tracks$year = year(tracks$date)
    tracks$platform = 'plane'
    tracks$name = 'tc_dash7'
    tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
    
    # add to list
    TRK[[i]] = tracks
    
    # catch null error
    if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
    
  }
  
} else {
  
  # make empty data frame
  TRK = data.frame()
  
}

# combine and save --------------------------------------------------------

# combine all flights
TRACKS = bind_rows(TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, file = ofile)
