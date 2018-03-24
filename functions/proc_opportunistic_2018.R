# directory to look for files
data_dir = 'data/raw/2018_opportunistic_sightings/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
library(data.table, quietly = T, warn.conflicts = F)
source('functions/config_data.R')
source('functions/clean_latlon.R')

# process data ------------------------------------------------------------

# read in spp and obs keys
sig = fread(paste0(data_dir, '/2018-narw-opportunistic-sightings.csv'))
sig = as.data.frame(sig)
colnames(sig) = c('date', 'time', 'lat', 'lon', 'number', 'platform', 'photos', 'verified', 'notes')

# pass blank table if input is empty
if(nrow(sig) == 0){
  
  # config data types
  sig = config_observations(sig)
  
  # save empty table
  saveRDS(sig, paste0(output_dir, '2018_opportunistic_sightings.rds'))
  
} else {
  
  # wrangle time
  time = paste0(sig$date, ' ', sig$time)
  sig$time = as.POSIXct(time, format = '%m/%d/%Y %H:%M:%S', tz = 'UTC', usetz=TRUE)
  
  # wrangle date
  sig$date = as.Date(sig$date, format = '%m/%d/%Y')
  sig$yday = yday(sig$date)
  sig$year = year(sig$date)
  
  # wrangle text
  sig$verified = tolower(sig$verified)
  sig$photos = tolower(sig$photos)
  
  # sighting info
  sig$species = 'right'
  sig$score = 'possibly sighted'
  sig$score[sig$verified == 'yes'] = 'sighted'
  
  # remove columns
  sig$photos = NULL
  sig$notes = NULL
  sig$verified = NULL
  
  # convert number to numeric
  sig$number = as.character(sig$number)
  sig$number = gsub(pattern = "\\?", replacement = NA, x = sig$number)
  sig$number = as.numeric(sig$number)
  
  # clean lat lons
  sig = clean_latlon(sig)
  
  # add metadata
  sig$name = sig$platform
  sig$platform = 'opportunistic'
  sig$id = paste0(sig$date, '_', sig$platform, '_', sig$name)
  
  # config data types
  sig = config_observations(sig)
  
  # save
  saveRDS(sig, paste0(output_dir, '2018_opportunistic_sightings.rds'))
}