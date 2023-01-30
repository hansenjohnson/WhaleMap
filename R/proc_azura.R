## proc_azura ##
# process survey data from azura consultant group

# input -------------------------------------------------------------------

# data directory
ddir = 'data/raw/azura/'

# outputs
obs_file = 'data/interim/azura_obs.rds'
eff_file = 'data/interim/azura_eff.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
suppressPackageStartupMessages(library(Hmisc))

# process -----------------------------------------------------------------

# list database files
flist = list.files(path = ddir, pattern = '*.mdb', full.names = T, recursive = T)

OBS = EFF = vector('list', length(flist))
for(ii in seq_along(OBS)){
  
  # read in database file
  tmp = mdb.get(flist[[ii]])
  
  # extract sightings and species codes
  obs = as_tibble(tmp$Sightings)
  
  # check species codes
  # codes = as_tibble(tmp$MammalCodes)
  # 2 = right, 4 = blue, 5 = fin, 6 = sei, 9 = humpback,
  
  # isolate time strings
  tmp_time = substr(as.character(obs$EntryTime), 10, 18)
  tmp_date = substr(as.character(obs$Date), 0, 8)
  
  # format
  obs %>%
    transmute(
      time = as.POSIXct(paste0(tmp_date, ' ', tmp_time), format = '%m/%d/%y %H:%M:%S', tz = 'UTC'),
      date = as.Date(time),
      year = year(date),
      yday = yday(date),
      lat = EntryLatitude,
      lon = EntryLongitude,
      species = SpeciesCode,
      score = 'definite visual',
      number = SpeCount,
      calves = Calves,
      platform = 'plane',
      name = 'azura',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    )
  
  # convert species codes
  obs$species[obs$species == '2'] = 'right'
  obs$species[obs$species == '4'] = 'blue'
  obs$species[obs$species == '5'] = 'fin'
  obs$species[obs$species == '6'] = 'sei'
  obs$species[obs$species == '9'] = 'humpback'
  
  # extract tracks
  eff = as_tibble(tmp$SurveyTrack)
  
  # isolate time strings
  tmp_time = substr(as.character(eff$Time), 10, 18)
  tmp_date = substr(as.character(eff$Date), 0, 8)
  
  # format
  eff = eff %>%
    transmute(
      time = as.POSIXct(paste0(tmp_date, ' ', tmp_time), format = '%m/%d/%y %H:%M:%S', tz = 'UTC'),
      date = as.Date(time),
      year = year(date),
      yday = yday(date),
      lat = Latitude,
      lon = Longitude,
      speed = NA,
      altitude = NA,
      platform = 'plane',
      name = 'azura',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    )
  
  # store
  OBS[[ii]] = obs
  EFF[[ii]] = eff
}

# collapse data
observations = bind_rows(OBS) %>% config_observations()
effort = bind_rows(EFF) %>% config_tracks()

# save
saveRDS(observations, file = obs_file)
saveRDS(effort, file = eff_file)
