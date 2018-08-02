## proc_2018_tc_dash8_tracks ##
# Process gps data from TC Dash-8 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/TC_dash8/'

# output file name
ofile = '2018_tc_dash8_tracks.rds'

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
source('functions/roundTen.R')
source('functions/plot_save_track.R')
source('functions/on_server.R')

# plot tracks?
plot_tracks = !on_server()

# list files to process
flist = list.files(data_dir, pattern = '^(\\d{8})_Dash8_tracklog.*.csv$', full.names = T, recursive = T)

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
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
  tracks$name = 'tc_dash8'
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


# add extra kml file(s) ---------------------------------------------------

# # list files to process
# flist2 = list.files(data_dir, pattern = 'FlightTrackPositions.*.kml$', full.names = T, recursive = T)
# 
# for(j in seq_along(flist2)){
#   
#   # library
#   library(xml2)
#   
#   # read in xml
#   x = read_xml(flist2[j])
#   
#   # explore contents
#   xml_name(x)
#   xml_children(x)
#   xml_attrs(x)
#   
#   # find start time, which is in the first 'EVENT' node
#   t0 = xml_find_first(x, "time")
#   
#   # extract the timestamp, saved in the attribute 'TIME'
#   t0 = xml_attr(t0, "TIME")
#   
#   # read in data
#   tmp = getKMLcoordinates(flist2[j], ignoreAltitude = TRUE)
#   tmp = do.call(rbind.data.frame, tmp)
#   
#   
# }

# combine and save --------------------------------------------------------

# catch errors
if(length(TRK)!=length(flist)){stop('Not all tracks were processed!')}

# combine all flights
TRACKS = do.call(rbind, TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
