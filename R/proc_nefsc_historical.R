## proc_nefsc_historical ##
# Process gps and sightings data from NOAA Twin Otter survey plane

# user input --------------------------------------------------------------

# minimum year
min_year = 2014

# data file
ifile = 'data/raw/nefsc/NARWSS-data-all-thru-end-2018.csv'

# output file names
track_file = 'nefsc_historical_tracks.rds'
sighting_file = 'nefsc_historical_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(tidyverse))
source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'MIWH', 'SEWH', 'HUWH','BLWH'),
  species = c('fin', 'right', 'minke', 'sei', 'humpback','blue'))

# process -----------------------------------------------------------------

# read in file
tmp = suppressWarnings(read_csv(ifile, col_types = cols()))

# wrangle time
tmp$time = as.POSIXct(paste0(tmp$DATE_LOCAL, ' ', tmp$TIME_LOCAL), format = '%d-%b-%y %H:%M:%S', tz = 'America/New_York', usetz = T)
tmp$time = with_tz(tmp$time, tzone = 'UTC')

# other time vars
tmp$date = as.Date(tmp$time)
tmp$yday = yday(tmp$time)
tmp$year = year(tmp$time)

# add deployment metadata
tmp$platform = 'plane'
tmp$name = 'noaa_twin_otter'
tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')

# filter 
tmp = tmp %>% filter(year >= min_year)

# tracklines --------------------------------------------------------------

# use all data for tracklines
trk = tmp

# extract lat/lon
trk$lat = trk$LATITUDE
trk$lon = trk$LONGITUDE

# get speed and altitude
trk$altitude = trk$ALTITUDE
trk$speed = trk$SPEED

# take important columns
trk = trk[,c('time','lat','lon', 'altitude','speed','date','yday', 'year','platform', 'name', 'id')]

# re-order
trk = trk[order(trk$time, decreasing = TRUE),]

# simplify by day
ids = unique(trk$id)
TRK = vector('list', length(ids))
for(ii in 1:length(ids)){
  TRK[[ii]] = trk %>% filter(id == ids[ii]) %>% subsample_gps()
}

# flatten tracks
tracks = bind_rows(TRK)

# compare
# ggplot()+
#   geom_path(data = filter(trk,year==2017), aes(x=lon,y=lat,group=id), color = 'red',alpha = 0.5, size = 2)+
#   geom_path(data = filter(tracks,year==2017), aes(x=lon,y=lat,group=id), color = 'blue', alpha = 0.5)+
#   theme_bw()

# sightings ---------------------------------------------------------------

# take only sightings
sig = tmp[which(!is.na(tmp$SPCODE)),]

# extract data
sig$lat = sig$LATITUDE
sig$lon = sig$LONGITUDE
sig$number = as.numeric(as.character(sig$GROUP_SIZE))
sig$calves = sig$CALVES

# get score
sig$score = NA
sig$score[which(sig$number>0)] = 'sighted'

# find indecies of matching
mind = match(table = spp_key$code, x = sig$SPCODE)

# replace codes with species names
sig$species = spp_key$species[mind]

# drop unknown codes
sig = sig[which(!is.na(sig$species)),]

# keep important columns
sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id','calves')]

# prep track output -------------------------------------------------------

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, track_file))

# prep sightings output ---------------------------------------------------

# config data types
sightings = config_observations(sig)

# save
saveRDS(sightings, paste0(output_dir, sighting_file))

# # test
# ggplot()+
#   geom_path(data = filter(tracks,year==2018), aes(x=lon,y=lat,group=id))+
#   geom_point(data = filter(sightings,year==2018), aes(x=lon,y=lat,color=species))+
#   coord_quickmap()
