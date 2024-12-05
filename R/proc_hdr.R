## proc_hdr ##
# process survey data from hdr consultant group
# requires external p7zip package
# easiest to install on mac/homebrew with `brew install p7zip`

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
flist = list.files(path = ddir, pattern = '*.mpk', full.names = T, recursive = T)

OBS = EFF = vector('list', length(flist))
for(ii in seq_along(OBS)){
  
  # define ifile
  ifile = flist[[ii]]
  
  # define temporary directory to extract files to
  tmpdir = tempdir()
  
  # extract file in temporary directory
  system(paste0('7z x ', ifile, ' -o', tmpdir, ' -aoa'), ignore.stdout = TRUE)
  
  # path to extracted file
  zfile = paste0(tmpdir, '/commondata/compass_ocsaerial.gdb/')
  
  # read in observations
  obs = st_read(zfile, layer = "Observation", quiet = TRUE) %>%
    as.data.frame()
  
  # format observations
  obs = obs %>%
    transmute(
      time = as.POSIXct(as.character(DateTime), tz = 'UTC'),
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
    config_observations()
  
  # fix species codes
  obs$species = factor(obs$species, 
                       levels = c('Eubalaena glacialis','Balaenoptera musculus','Balaenoptera physalus','Balaenoptera borealis','Megaptera novaeangliae'), 
                       labels = c('right','blue','fin','sei','humpback'))
  
  # drop bad data
  obs = obs %>%
    filter(!is.na(lat) & !is.na(lon) & !is.na(time) & !is.na(species))
  
  # store obs
  OBS[[ii]] = obs
  
  # read in effort
  eff = st_read(zfile, layer = "PlatformTrackPoint", quiet = TRUE) %>%
    as.data.frame()
  
  # unique dates
  eff$date = as.Date(eff$DateTime)
  dts = unique(eff$date)
  
  SEG = vector('list', length(dts))
  for(jj in seq_along(dts)){
    
    SEG[[jj]] = eff %>% 
      filter(date == dts[jj]) %>%
      transmute(
        time = as.POSIXct(as.character(DateTime), tz = 'UTC'),
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
    
  }
  
  # collapse
  eff = bind_rows(SEG)
  
  # drop NA
  eff = eff %>% filter(!is.na(time) & !is.na(lat) & !is.na(lon))
  
  # store eff
  EFF[[ii]] = eff
  
  # remove temporary directory
  # system(paste0("rm -r ", tmpdir))
}

# collapse data
observations = bind_rows(OBS)
effort = bind_rows(EFF)

# save
saveRDS(observations, file = obs_file)
saveRDS(effort, file = eff_file)
