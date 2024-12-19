## proc_hdr ##
# process survey data from hdr consultant group

# input -------------------------------------------------------------------

# data directory
ddir = 'data/raw/hdr'

# outputs
obs_file = 'data/interim/hdr_obs.rds'
eff_file = 'data/interim/hdr_eff.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# process -----------------------------------------------------------------

# list database files
olist = list.files(path = ddir, pattern = '*_sighting.csv$', full.names = T, recursive = T)
elist = list.files(path = ddir, pattern = '*_track_points.csv$', full.names = T, recursive = T)

OBS = vector('list', length(olist))
EFF = vector('list', length(elist))
for(ii in seq_along(OBS)){
  
  # define ifile
  ifile = olist[[ii]]
  
  # read in observations
  obs = read_csv(ifile, show_col_types = FALSE)
  
  # format observations
  obs = obs %>%
    transmute(
      time = as.POSIXct(as.character(DateTime), format = "%m/%d/%Y %H:%M", tz = 'UTC'),
      date = as.Date(time),
      year = year(date),
      yday = yday(date),
      lat = LatAnimal,
      lon = LongAnimal,
      species = SpcsNmSci,
      score = "definite visual",
      number = CountTotBest,
      calves = CountCalves,
      platform = 'plane',
      name = 'hdr',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    ) %>%
    config_observations() %>%
    as.data.frame()
  
  # fix species codes
  obs$species = factor(obs$species, 
                       levels = c('Eubalaena glacialis','Balaenoptera musculus','Balaenoptera physalus','Balaenoptera borealis','Megaptera novaeangliae'), 
                       labels = c('right','blue','fin','sei','humpback'))
  
  # drop bad data
  obs = obs %>%
    filter(!is.na(lat) & !is.na(lon) & !is.na(time) & !is.na(species))
  
  # store obs
  OBS[[ii]] = obs
}

for(ii in seq_along(EFF)){
  
  # define ifile
  ifile = elist[[ii]]
  
  # read in effort
  eff = read_csv(ifile, show_col_types = FALSE)
  
  # format
  eff = eff %>%
    transmute(
      time = as.POSIXct(as.character(DateTime), format = "%m/%d/%Y %H:%M", tz = 'UTC'),
      date = as.Date(time),
      year = year(date),
      yday = yday(date),
      lat = LatPlatform,
      lon = LongPlatform,
      speed = NA,
      altitude = NA,
      platform = 'plane',
      name = 'hdr',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    ) %>%
    arrange(time) %>%
    config_tracks() %>%
    subsample_gps()
  
  # drop NA
  eff = eff %>% filter(!is.na(time) & !is.na(lat) & !is.na(lon))
  
  # store eff
  EFF[[ii]] = eff
}

# collapse data
observations = bind_rows(OBS)
effort = bind_rows(EFF)

# save
saveRDS(observations, file = obs_file)
saveRDS(effort, file = eff_file)
