# process and save all 2018 neaq sightings and tracklines

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2018_neaq_nereid/'

# directory for output
output_dir = 'data/interim/'

# subsample gps?
subsample = FALSE

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('functions/config_data.R')
source('functions/subsample_gps.R')

# read in spp and obs keys
spp_key = read.csv(paste0(data_dir, '/species_key.csv'))

# list data files
dfiles = list.files(data_dir, pattern = '*NEA-V.csv$', full.names = T)

ALL = list()
for(i in seq_along(dfiles)){
  
  # determine filename
  ifile = dfiles[i]
  
  # read in data
  ALL[[i]] = read.csv(ifile)
}

# combine into single table
all = do.call(rbind.data.frame, ALL)

# fix time
all$time = as.POSIXct(all$Time, tz = 'UTC', usetz = T)

# find start and end of surveys
ind = which(all$LEGSTAGE==1|all$LEGSTAGE==5) 

# replace these lat lons with NAs to stop plotting
all$TrkLatitude[ind] = NA 
all$TrkLongitude[ind] = NA

# wrangle time
all$date = as.Date(all$time)
all$yday = yday(all$time)
all$year = year(all$time)

# add deployment metadata
all$platform = 'vessel'
all$name = 'nereid'
all$id = paste(all$date, all$platform, all$name, sep = '_')

# tracks ------------------------------------------------------------------

# take only on-effort tracklines
tracks = all[which(all$LEGSTAGE==1 | all$LEGSTAGE==5 | all$LEGSTAGE==2),]

# fix lat lons
tracks$lat = tracks$TrkLatitude
tracks$lon = tracks$TrkLongitude

# remove unused columns
tracks = tracks[,c('time','lat','lon', 'date','yday', 'year',  'platform', 'name', 'id')]

# subsample
if(subsample){
  tracks = subsample_gps(gps = tracks)
} else {
  message('Not subsampling tracklines!')
}

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, '2018_neaq_nereid_tracks.rds'))

# sightings ---------------------------------------------------------------

# take only sightings
sig = droplevels(all[which(as.character(all$SPECCODE)!=""),])

# get lat lons
sig$lat = sig$LAT...SIGHTINGS
sig$lon = sig$LONG...SIGHTINGS

# get number of individuals
sig$number = sig$NUMBER...SIGHTINGS

# get score
sig$score[which(sig$number>0)] = 'sighted'

# find indecies of matching
mind = match(table = spp_key$code, x = sig$SPECCODE)

# replace codes with species names
sig$species = spp_key$species[mind]

# drop unknown codes
sig = sig[which(!is.na(sig$species)),]

# keep important columns
sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, paste0(output_dir, '2018_neaq_nereid_sightings.rds'))
