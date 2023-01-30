## proc_sotw ##
# process visual survey data from R/V Song Of The Whale

# input -------------------------------------------------------------------

# data directory
ddir = 'data/raw/sotw/'

# output files
obs_ofile = 'data/interim/sotw_obs.rds'
eff_ofile = 'data/interim/sotw_eff.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# sightings ---------------------------------------------------------------

# find data files
obs_files = list.files(path = ddir, pattern = 'Sightings', full.names = T, recursive = T)

OBS = vector('list', length(obs_files))
for(ii in seq_along(OBS)){
  
  # read in data
  tmp = read_csv(obs_files[ii], show_col_types = FALSE)
  
  # format
  obs = tmp %>%
    transmute(
      time = as.POSIXct(Time_UTC, format = '%d/%m/%Y %H:%M:%S', tz = 'UTC'),
      date = as.Date(time),
      year = year(date),
      yday = yday(date),
      lat = Latitude,
      lon = Longitude,
      species = SpeciesCode,
      score = Conf_ID,
      number = MinNo,
      calves = NA,
      platform = 'vessel',
      name = 'sotw',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    )
 
  # fix species codes
  obs$species[obs$species == 'NRW'] = 'right'
  obs$species[obs$species == 'HUW'] = 'humpback'
  obs$species[obs$species == 'BLW'] = 'blue'
  obs$species[obs$species == 'FIW'] = 'fin'
  obs$species[obs$species == 'SEW'] = 'sei'
  
  # fix scores
  obs$score[obs$score == 'Def'] = 'definite visual'
  obs$score[obs$score %in% c('Poss', 'Prob')] = 'possible visual'
   
  # store
  OBS[[ii]] = obs
}

# flatten list and format
observations = bind_rows(OBS) %>% config_observations()

# save
saveRDS(observations, obs_ofile)

# effort ------------------------------------------------------------------

eff_files = list.files(path = ddir, pattern = 'GpsData', full.names = T, recursive = T)

EFF = vector('list', length(eff_files))
for(ii in seq_along(EFF)){
  
  # read in data
  tmp = read_csv(eff_files[ii], show_col_types = FALSE)
  
  # format
  eff = tmp %>%
    transmute(
      time = as.POSIXct(Time_UTC, format = '%d/%m/%Y %H:%M:%S', tz = 'UTC'),
      date = as.Date(time),
      year = year(date),
      yday = yday(date),
      lat = Latitude,
      lon = Longitude,
      speed = NA,
      altitude = NA,
      platform = 'vessel',
      name = 'sotw',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    )
  
  # add to list
  EFF[[ii]] = eff
}

# flatten list and format
effort = bind_rows(EFF) %>% config_tracks()

# sort by time
effort = effort %>% arrange(time)

# save
saveRDS(effort, eff_ofile)
