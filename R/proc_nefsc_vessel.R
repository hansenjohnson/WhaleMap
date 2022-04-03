## proc_nefsc_vessel ##
# process sightings and tracklines from NEFSC vessel(s)

# input -------------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/nefsc_vessel/'

# directory for output
trk_ofile = 'data/interim/nefsc_vessel_eff.rds'
obs_ofile = 'data/interim/nefsc_vessel_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# process gpx -------------------------------------------------------------

# list gpx tracks
flist = list.files(data_dir, pattern = '\\d{8}_*.*_Garmin_Trackline.gpx$', ignore.case = T, full.names = T, recursive = T)

# extract GPS data
TRK = vector('list', length = length(flist))
for(ii in seq_along(flist)){
  
  # isolate file
  ifile = flist[ii]
  
  # read in GPX data
  tmp = read_GPX(ifile)
  
  # wrangle time
  tmp$time = as.POSIXct(tmp$time, format = '%Y-%m-%d %H:%M:%S', tz = 'UTC')
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  tmp$source = 'WhaleMap'
  
  # add deployment metadata
  tmp$name = tolower(strsplit(basename(ifile), '_')[[1]][2])
  tmp$platform = 'vessel'
  tmp$id = paste(min(tmp$date, na.rm = T), tmp$platform, tmp$name, sep = '_')
  
  # simplify
  tmp = subsample_gps(tmp)
  
  # configure
  TRK[[ii]] = config_tracks(tmp)
}

# combine
tracks_gpx = bind_rows(TRK)

# process wjr tracks ------------------------------------------------------

# read in tracks
tmp = read.csv(paste0(data_dir,'/WJR2021gpstotal.csv'), stringsAsFactors = F)

# convert lat / lon
tmp$lat = tmp$Latitude
tmp$lon = tmp$Longitude

# wrangle time
tmp$date = as.Date(tmp$Date, format = '%d-%b-%y')
tmp$time = as.POSIXct(paste0(tmp$date, ' ', tmp$Time), format = '%Y-%m-%d %H:%M:%S %p', tz = 'UTC')
tmp$yday = yday(tmp$time)
tmp$year = year(tmp$time)
tmp$source = 'WhaleMap'

# add deployment metadata
tmp$name = 'wjr'
tmp$platform = 'vessel'
tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')

# simplify
tmp = tmp %>%
  group_by(id) %>%
  group_modify(~ subsample_gps(.x)) %>%
  ungroup()

# configure  
tracks_wjr = config_tracks(tmp)  

# process wjr sightings ---------------------------------------------------

# read in tracks
tmp = read.csv(paste0(data_dir,'/WJR2021sighttotal.csv'), stringsAsFactors = F)

# convert lat / lon
tmp$lat = tmp$EntryLatitude
tmp$lon = tmp$EntryLongitude

# wrangle time
tmp$date = as.Date(tmp$Date, format = '%d-%b-%y')
tmp$time = as.POSIXct(paste0(tmp$date, ' ', tmp$EntryTime), format = '%Y-%m-%d %H:%M:%S', tz = 'UTC')
tmp$yday = yday(tmp$time)
tmp$year = year(tmp$time)
tmp$source = 'WhaleMap'

# add deployment metadata
tmp$name = 'wjr'
tmp$platform = 'vessel'
tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')

# add sightings data
tmp$species = NA
tmp$species[tmp$SpeciesCode == 'HUWH'] = 'humpback'
tmp$species[tmp$SpeciesCode == 'RIWH'] = 'right'
tmp$species[tmp$SpeciesCode == 'FIWH'] = 'fin'
tmp$species[tmp$SpeciesCode == 'SEWH'] = 'sei'

tmp$number = tmp$GroupSize
tmp$calves = tmp$Calves
tmp$calves[tmp$Calves < 0] = NA

tmp$score = NA
tmp$score[tmp$Confidence == 'certain'] = 'sighted'
tmp$score[tmp$Confidence %in% c('probably', 'not sure')] = 'possibly sighted'

# configure
obs = config_observations(tmp)
obs = obs[!is.na(obs$species),]

# save --------------------------------------------------------------------

# combine tracks
trk = rbind(tracks_gpx, tracks_wjr)

# save tracks
saveRDS(trk, trk_ofile)

# save sightings
saveRDS(obs, obs_ofile)
