# process and save noaa plane sightings and tracklines

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2015_noaa_plane/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate)
source('functions/config_data.R')

# read in spp and obs keys
spp_key = read.csv(paste0(data_dir, '/noaa_species_key.csv'))

# list all files with 6 digit names (noaa convention)
paths = list.files(data_dir, pattern = '\\D*(\\d{6})', full.names = T)

# prep for loop
GPS = list()
SIG = list()

# process files -----------------------------------------------------------

for(i in seq_along(paths)){
  
  # select directory
  noaa_dir = paths[[i]]
  
  # extract start date
  start_date = format(as.POSIXct(basename(noaa_dir), format = '%y%m%d'), format = '%Y-%m-%d')
  
  # paths to files
  gps_file = list.files(path = noaa_dir, pattern = '.gps', full.names = T)
  sig_file = list.files(path = noaa_dir, pattern = '.sig', full.names = T)
  
  # process gps file --------------------------------------------------------
  
  # read in gps file
  gps = read.table(gps_file, sep = ',')
  
  # drop unused columns
  gps = gps[,-c(4:7)]
  
  # rename
  colnames(gps) = c('time', 'lat', 'lon')
  
  # wrangle time
  gps$time = as.POSIXct(gps$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
  gps$date = as.Date(gps$time)
  gps$yday = yday(gps$time)
  gps$year = year(gps$time)
  
  # add deployment metadata
  # gps$start_date = start_date
  gps$platform = 'plane'
  gps$name = 'noaa'
  gps$id = paste0(start_date, '_plane_noaa')
  
  GPS[[i]] = gps
  
  # process sightings file --------------------------------------------------
  
  # read in sig file
  sig = read.table(sig_file, sep = ',')
  
  # drop unused columns
  sig = sig[,-c(1:3, 5:6, 9:14, 17:21)]
  
  # rename columns
  colnames(sig) = c('time', 'species', 'number', 'lat', 'lon')
  
  # wrangle time
  sig$time = as.POSIXct(sig$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
  sig$date = as.Date(sig$time)
  sig$yday = yday(sig$time)
  sig$year = year(sig$time)
  
  # add deployment metadata
  sig$platform = 'plane'
  sig$name = 'noaa'
  sig$id = paste0(start_date, '_plane_noaa')
  
  # find indecies of matching
  mind = match(table = spp_key$code, x = sig$species)
  
  # replace codes with species names
  sig$species = spp_key$species[mind]
  
  # remove incomplete cases
  sig = sig[complete.cases(sig),]
  
  # add to list
  SIG[[i]] = sig
}

# check performance
if(length(GPS)!=length(paths)){warning('Not all deployments were processed!')}
if(length(SIG)!=length(paths)){warning('Not all deployments were processed!')}

# combine and save data ---------------------------------------------------

# flatten data
tracks = do.call(rbind, GPS)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, '2015_noaa_tracks.rds'))

# add score
sightings$score[which(sightings$number>0)] = 'sighted'

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, paste0(output_dir, '2015_noaa_sightings.rds'))
