## proc_2018-04-03_dfo_transit ##
# Process one-off transit flight from the DFO twin otter. Data provided by Jack Lawson on 2018-04-20

# user input --------------------------------------------------------------

# track file
tfile = 'data/raw/2018_whalemapdata/DFO_twin_otter/20180403_transit/3 April 2018 Otter Search and Deployment Track.gpx'
sfile = 'data/raw/2018_whalemapdata/DFO_twin_otter/20180403_transit/April Deployment Flight Sightings.xls'

# output file names
tofile = '2018-04-03_dfo_twin_otter_tracks.rds'
sofile = '2018-04-03_dfo_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
library(readxl, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')
source('functions/subsample_gps.R')
source('functions/plot_save_track.R')
source('functions/on_server.R')

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
tracks$name = 'dfo'
tracks$id = paste0(tracks$date, '_plane_dfo')

# config flight data
tracks = config_tracks(tracks)

# plot track
if(plot_tracks){
  plot_save_track(tracks, tfile)
}

# save
saveRDS(tracks, paste0(output_dir, tofile))

# process sightings -------------------------------------------------------

# read in data from excel
obs = as.data.frame(read_xls(sfile))

# add data
obs$date = as.Date(paste0(obs$Year, '-', obs$Month, '-', obs$Day))
obs$time = NA
obs$lat = obs$Latitude
obs$lon = obs$Longitude
obs$number = obs$Number
obs$yday = yday(obs$date)
obs$year = year(obs$date)
obs$score = 'sighted'
obs$platform = 'plane'
obs$name = 'dfo'
obs$id = paste(obs$date, obs$platform, obs$name, sep = '_')

# fix species
obs$species = NA
obs$species[obs$Species == 'Large Whale'] = 'unknown whale'
obs$species[obs$Species == 'White-beaked Dolphin'] = 'white-beaked dolphin'
obs$species[obs$Species == 'Blue Whale'] = 'blue'
obs$species[obs$Species == 'Fin Whale' | obs$Species == '1 Fin Whale'] = 'fin'

# remove unused columns
obs = obs[-c(1:7)]

# config sightings data
obs = config_observations(obs)

# save
saveRDS(obs, paste0(output_dir, sofile))
