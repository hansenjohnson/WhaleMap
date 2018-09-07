## proc_2018_dfo_tag_vessel_sightings ##
# process right whales sightings from DFO tagging vessel

# directory to look for files
data_dir = 'data/raw/2018_whalemapdata/DFO_vessel_cetus/'

# directory for output
output_dir = 'data/interim/'

# output file name
ofile = '2018_dfo_cetus_sightings.rds'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
library(data.table, quietly = T, warn.conflicts = F)
library(measurements)
source('functions/config_data.R')
source('functions/clean_latlon.R')

# process data ------------------------------------------------------------

# read in spp and obs keys
sig = fread(paste0(data_dir, '/2018-dfo-cetus-sightings.csv'))
sig = as.data.frame(sig)
colnames(sig) = c('date', 'time', 'lat', 'lon', 'number', 'photos', 'notes')

# pass blank table if input is empty
if(nrow(sig) == 0){
  
  # config data types
  sig = config_observations(sig)
  
  # save empty table
  saveRDS(sig, paste0(output_dir, ofile))
  
} else {
  
  # wrangle time
  time = paste0(sig$date, ' ', sig$time)
  sig$time = as.POSIXct(time, format = '%Y-%m-%d %H:%M', tz = 'UTC', usetz=TRUE)
  
  # wrangle date
  sig$date = as.Date(sig$date, format = '%Y-%m-%d')
  sig$yday = yday(sig$date)
  sig$year = year(sig$date)
  
  # sighting info
  sig$species = 'right'
  sig$score = 'sighted'
  sig$platform = 'vessel'
  sig$name = 'dfo_cetus'
  sig$id = paste0(sig$date, '_', sig$platform, '_', sig$name)
  
  # remove columns
  sig$photos = NULL
  sig$notes = NULL
  
  # convert number to numeric
  sig$number = as.character(sig$number)
  sig$number = gsub(pattern = "\\?", replacement = NA, x = sig$number)
  sig$number = as.numeric(sig$number)
  
  # convert lat lons
  sig$lat = as.numeric(conv_unit(sig$lat, from = 'deg_dec_min', to = 'dec_deg'))
  sig$lon = abs(as.numeric(conv_unit(sig$lon, from = 'deg_dec_min', to = 'dec_deg')))*-1
  
  # config data types
  sig = config_observations(sig)
  
  # save
  saveRDS(sig, paste0(output_dir, ofile))
}