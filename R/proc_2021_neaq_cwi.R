## proc_2021_neaq_cwi ##
# process and save all 2021 neaq/cwi sightings and tracklines

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2021_neaq_cwi/'

# directory for output
obs_ofile = 'data/interim/2021_neaq_vessel_sightings.rds'
trk_ofile = 'data/interim/2021_neaq_vessel_tracks.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'MIWH', 'SEWH', 'HUWH', 'HAPO', 'GRSE', 'PIWH'),
  species = c('fin', 'right', 'minke', 'sei', 'humpback', 'harbor porpoise', 'grey seal','pilot whale'))

# list sightings files
sig_list = list.files(data_dir, pattern = '\\SIGHTINGS*.*.csv$', full.names = T, include.dirs = F)
trk_list = list.files(data_dir, pattern = '\\Track-*.*.csv$', full.names = T, include.dirs = F)

## sightings
SIG = vector('list', length = length(sig_list))
for(isig in seq_along(sig_list)){

  # read in sightings file
  tmp = read.csv(sig_list[isig])
  
  # assign vessel and timezone
  tmp$time = as.POSIXct(tmp$date.time..ADT., format = '%Y-%m-%dT%H:%M:%S', tz = 'America/Halifax')
  
  # wrangle time
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # add deployment metadata
  tmp$platform = 'vessel'
  tmp$name = 'jdmartin'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # take only sightings
  sig = droplevels(tmp[which(as.character(tmp$SPECCODE)!=""),])

  # extract data
  sig$lat = sig$LATITUDE
  sig$lon = sig$LONGITUDE
  sig$number = sig$NUMBER
  sig$calves = as.numeric(as.character(sig$NUMCALF))

  # assume zero calves if na
  sig$calves = ifelse(is.na(sig$calves), 0, 1)

  # get score
  sig$score = NA
  sig$score[sig$IDREL %in% c(1,2)] = 'possibly sighted'
  sig$score[sig$IDREL == 3] = 'sighted'

  # find indecies of matching
  mind = match(table = spp_key$code, x = sig$SPECCODE)

  # replace codes with species names
  sig$species = spp_key$species[mind]

  # drop unknown codes
  sig = sig[which(!is.na(sig$species)),]

  # keep important columns
  sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','calves','year','platform','name','id')]

  # add to the list
  SIG[[isig]] = sig
}

## tracks
TRK = vector('list', length = length(trk_list))
for(itrk in seq_along(trk_list)){
  
  # read in sightings file
  tmp = read.csv(trk_list[itrk])
  
  # assign vessel and timezone
  tmp$time = as.POSIXct(tmp$Time.Created..ADT., format = '%Y-%m-%dT%H:%M:%S', tz = 'America/Halifax')
  
  # wrangle time
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # add deployment metadata
  tmp$platform = 'vessel'
  tmp$name = 'jdmartin'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')

  # add lat/lon/speed/alt
  tmp$lat = tmp$Latitude
  tmp$lon = tmp$Longitude
  tmp$speed = tmp$Speed.Over.Ground..kts.
  tmp$altitude = tmp$Altitude..m.
  
  # select columns
  trk = tmp[,c('time','lat','lon', 'altitude','speed','date','yday', 'year', 'platform', 'name', 'id')]
  
  # simplify
  trk = subsample_gps(gps = trk, tol = 0.00025)

  # add to list
  TRK[[itrk]] = trk
}

# prep track output -------------------------------------------------------

# combine all tracks
tracks = bind_rows(TRK)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, trk_ofile)

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = bind_rows(SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, obs_ofile)
