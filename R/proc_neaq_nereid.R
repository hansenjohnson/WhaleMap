## proc_neaq_nereid ##
# process and save all sightings and tracklines from neaq vessel nereid

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/neaq/nereid/'

# directory for output
eff_file = 'data/interim/neaq_nereid_eff.rds'
obs_file = 'data/interim/neaq_nereid_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'MIWH', 'SEWH', 'HUWH', 'HAPO', 'GRSE', 'PIWH'),
  species = c('fin', 'right', 'minke', 'sei', 'humpback', 'harbor porpoise', 'grey seal','pilot whale'))

# list data files
flist = list.files(data_dir, pattern = '*Whalemap.csv$', full.names = T, include.dirs = F)

TRK = SIG = vector('list', length = length(flist))
for(ii in seq_along(flist)){
  
  # read in data
  tmp = read.csv(flist[ii])
  
  # assign vessel and timezone
  itz = 'America/New_York'
  ivs = 'nereid'
  tmp$time = as.POSIXct(tmp$TrkTime..EDT., tz = itz, format = '%Y-%m-%dT%H:%M:%S')
  
  # convert to UTC
  tmp$time = with_tz(tmp$time, tzone = 'UTC')
  
  # wrangle time
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # add deployment metadata
  tmp$platform = 'vessel'
  tmp$name = ivs
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # tracklines --------------------------------------------------------------
  
  # switch to track
  trk = tmp
  
  # fix lat lons
  trk$lat = trk$TrkLatitude
  trk$lon = trk$TrkLongitude
  
  # get speed and altitude
  trk$altitude = NA
  trk$speed = NA
  
  # remove unused columns
  trk = trk[,c('time','lat','lon', 'altitude','speed','date','yday', 'year', 'platform', 'name', 'id')]
  
  # simplify and store track
  TRK[[ii]] = subsample_gps(gps = trk)
  
  # sightings ---------------------------------------------------------------
  
  # take only sightings
  sig = droplevels(tmp[which(as.character(tmp$SPECCODE)!=""),])
  
  # extract data
  sig$lat = sig$Lat..vessel.
  sig$lon = sig$Long..vessel.
  sig$number = sig$NUMBER
  sig$calves = NA
  
  # get score
  sig$score[which(sig$number>0)] = 'sighted'
  
  # find indecies of matching
  mind = match(table = spp_key$code, x = sig$SPECCODE)
  
  # replace codes with species names
  sig$species = spp_key$species[mind]
  
  # drop unknown codes
  sig = sig[which(!is.na(sig$species)),]
  
  # keep important columns
  sig = sig[,c('time','lat','lon','date', 'yday','species','score','number', 'calves', 'year','platform','name','id')]
  
  # add to the list
  SIG[[ii]] = sig
  
}

# prep track output -------------------------------------------------------

# combine all tracks
tracks = bind_rows(TRK)

# add data source
tracks$source = 'WhaleMap'

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, eff_file)

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = bind_rows(SIG)

# add data source
sightings$source = 'WhaleMap'

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, obs_file)