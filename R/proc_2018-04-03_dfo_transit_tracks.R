## proc_2018-04-03_dfo_transit_tracks ##
# Process one-off transit flight from the DFO twin otter. Data provided by Jack Lawson on 2018-04-20

# user input --------------------------------------------------------------

# track file
tfile = 'data/raw/2018_whalemapdata/DFO_twin_otter/20180403_transit/3 April 2018 Otter Search and Deployment Track.gpx'

# output file names
tofile = '2018-04-03_dfo_twin_otter_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
library(readxl, quietly = T, warn.conflicts = F)

# functions
source('R/functions.R')

# plot tracks?
plot_tracks = !on_server()

# process tracks ----------------------------------------------------------

# read in file
tmp = readOGR(dsn = tfile, layer="track_points", verbose = F)

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
tracks$name = 'dfo_twin_otter'
tracks$id = paste0(tracks$date, '_plane_dfo_twin_otter')

# config flight data
tracks = config_tracks(tracks)

# plot track
if(plot_tracks){
  plot_save_track(tracks, tfile)
}

# save
saveRDS(tracks, paste0(output_dir, tofile))