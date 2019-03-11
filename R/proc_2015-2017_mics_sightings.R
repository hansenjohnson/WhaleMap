## proc_2015-2017_mics_sightings
# Process right whale sightings data from MICS survey vessels

# user input --------------------------------------------------------------

# sightings data file
data_file = 'data/raw/2015-2017_mics/sightings/RW sightings 2015 to 2017.xlsx'

# output file name
out_file = 'data/interim/2015-2017_mics_sightings.rds'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(measurements))
source('R/functions.R')

# process data ------------------------------------------------------------

# read in spp and obs keys
sig = as.data.frame(read_xlsx(data_file))

# define column names
colnames(sig) = c('date', 'platform', 'time', 'lat', 'lon', 'number', 'field_id', 'comments')

# fix date
sig$date = as.Date(sig$date, format = '%Y-%m-%d')

# remove row with bad date
sig = sig[!is.na(sig$date),]

# fix time
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

# remove bad positions
sig = sig[sig$lon != '0\t0' & sig$lat != '0\t0',]

# convert lat lons
sig$lat = gsub(sig$lat, pattern = '\t', replacement = ' ')
sig$lat = round(as.numeric(measurements::conv_unit(sig$lat, from = 'deg_min_sec', to = 'dec_deg')), 5)
sig$lon = gsub(sig$lon, pattern = '\t', replacement = ' ')
sig$lon = abs(round(as.numeric(measurements::conv_unit(sig$lon, from = 'deg_min_sec', to = 'dec_deg')), 5))*-1

# add metadata
sig$name = paste0('mics_', tolower(sig$platform))
sig$platform = 'vessel'
sig$id = paste0(sig$date, '_', sig$platform, '_', sig$name)

# select columns of interest
sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, out_file)
