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

# process -----------------------------------------------------------------

# list database files
flist = list.files(path = ddir, pattern = '*.mdb', full.names = T, recursive = T)

OBS = EFF = vector('list', length(flist))
for(ii in seq_along(OBS)){
  
  # define ifile
  ifile = flist[[ii]]
  
  # extract sightings and species codes
  obs = read_MDB(ifile, table_name = "Sightings")
  
  # check species codes
  # codes = as_tibble(tmp$MammalCodes)
  # 2 = right, 4 = blue, 5 = fin, 6 = sei, 9 = humpback,
  
  # isolate time strings
  tmp_time = substr(as.character(obs$EntryTime), 10, 18)
  tmp_date = substr(as.character(obs$Date), 0, 8)
  
  # format
  obs = obs %>%
    transmute(
      time = as.POSIXct(paste0(tmp_date, ' ', tmp_time), format = '%m/%d/%y %H:%M:%S', tz = 'UTC'),
      date = as.Date(time),
      year = year(date),
      yday = yday(date),
      lat = EntryLatitude,
      lon = EntryLongitude,
      species = SpeciesCode,
      score = 'definite visual',
      number = GroupSize,
      calves = Calves,
      platform = 'plane',
      name = 'azura',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    ) %>%
    config_observations()
  
  # convert species codes
  obs$species = factor(obs$species, levels = c('2','4','5','6','9'), 
         labels = c('right','blue','fin','sei','humpback'))
  
  # fix calves number
  obs$calves[obs$calves == -9] = NA
  
  # extract tracks
  eff = read_MDB(ifile, table_name = "SurveyTrack")
  
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
    ) %>%
    arrange(time) %>%
    config_tracks()
  
  # store
  OBS[[ii]] = obs
  EFF[[ii]] = eff
}

# collapse data
observations = bind_rows(OBS)
effort = bind_rows(EFF)

# save
saveRDS(observations, file = obs_file)
saveRDS(effort, file = eff_file)
