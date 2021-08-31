## proc_2021_mics_sightings ##
# process 2021 MICS right whales sightings

# input -------------------------------------------------------------------

# sightings data file
data_file = 'data/raw/2021_mics/Right Whale MICS 2021.xlsx'

# output file name
out_file = 'data/interim/2021_mics_sightings.rds'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(measurements))
source('R/functions.R')

# process data ------------------------------------------------------------

# read in spp and obs keys
sig = as.data.frame(read_xlsx(data_file))

# define column names
colnames(sig) = c('date', 'platform', 'time', 'lat', 'lon', 'number', 'field_id', 'photos', 'comments')

# pass blank table if input is empty
if(nrow(sig) == 0){
  
  # config data types
  sig = config_observations(sig)
  
  # save empty table
  saveRDS(sig, out_file)
  
} else {
  
  # fix time
  sig$date = as.Date(sig$date, format = '%Y-%m-%d')
  sig$time = paste0(hour(sig$time), ':', minute(sig$time), ':', second(sig$time))
  sig$time = as.POSIXct(paste0(sig$date, ' ', sig$time), tz = 'US/Eastern')
  
  # convert to UTC
  sig$time = as.POSIXct(format(sig$time, tz = 'UTC', usetz = TRUE), tz = 'UTC')
  
  # wrangle date
  sig$yday = yday(sig$date)
  sig$year = year(sig$date)
  
  # sighting info
  sig$species = 'right'
  sig$score = 'sighted'
  
  # convert lat lons
  sig$lat = round(as.numeric(measurements::conv_unit(sig$lat, from = 'deg_min_sec', to = 'dec_deg')), 5)
  sig$lon = abs(round(as.numeric(measurements::conv_unit(sig$lon, from = 'deg_min_sec', to = 'dec_deg')), 5))*-1
  
  # add metadata
  sig$name = sig$platform
  sig$platform = 'vessel'
  sig$id = paste0(sig$date, '_', sig$platform, '_', sig$name)
  sig$source = 'WhaleMap'
  
  # select columns of interest
  sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]
  
  # config data types
  sig = config_observations(sig)
  
  # save
  saveRDS(sig, out_file)
}