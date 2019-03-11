# process and save all shelagh sightings and tracklines

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2016_shelagh/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('R/functions.R')

# read in spp and obs keys
spp_key = read.csv(paste0(data_dir, '/shelagh_species_key.csv'))

# list data files
dfiles = list.files(data_dir, pattern = '*CWI-V*', full.names = T)

SHE = list()
for(i in seq_along(dfiles)){
  
  # determine filename
  ifile = dfiles[i]
  
  # read in data
  SHE[[i]] = read.csv(ifile)
}

# combine into single table
she = do.call(rbind.data.frame, SHE)

# add leading zeros to timestamps
she$MONTH = sprintf('%02d', she$MONTH)
she$DAY = sprintf('%02d', she$DAY)
she$TIME = sprintf('%06d', she$TIME)

# create timestamp vector
time = paste0(she$YEAR, '-', she$MONTH, '-', she$DAY, ' ', she$TIME)
she$time = as.POSIXct(time, format = '%Y-%m-%d %H%M%S', tz = 'UTC', usetz = T)

# find start and end of surveys
ind = which(she$LEGSTAGE==1|she$LEGSTAGE==5) 

# replace these lat lons with NAs to stop plotting
she$LATITUDE[ind] = NA 
she$LONGITUDE[ind] = NA

# wrangle time
she$date = as.Date(she$time)
she$yday = yday(she$time)
she$year = year(she$time)

# add deployment metadata
she$platform = 'vessel'
she$name = 'shelagh'
she$id = paste0(she$date, '_vessel_shelagh')

# tracks ------------------------------------------------------------------

# take only on effort tracklines
tracks = she[which(she$LEGSTAGE==1 | she$LEGSTAGE==5 | she$LEGSTAGE==2),]

# fix lat lons
tracks$lat = tracks$LATITUDE
tracks$lon = tracks$LONGITUDE

# remove unused columns
tracks = tracks[,-c(1:38)]

# subsample (use default subsample rate)
tracks = subsample_gps(gps = tracks)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, '2016_shelagh_tracks.rds'))

# sightings ---------------------------------------------------------------

# take only sightings
sig = droplevels(she[which(as.character(she$SPECCODE)!=""),])

# get lat lons
sig$lat = sig$LATITUDE
sig$lon = sig$LONGITUDE

# get number of individuals
sig$number = sig$NUMBER

# get score
sig$score[which(sig$number>0)] = 'sighted'

# find indecies of matching
mind = match(table = spp_key$code, x = sig$SPECCODE)

# replace codes with species names
sig$species = spp_key$species[mind]

# drop unknown codes
sig = sig[which(!is.na(sig$species)),]

# remove unused columns
sig = sig[,-c(1:38)]

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, paste0(output_dir, '2016_shelagh_sightings.rds'))
