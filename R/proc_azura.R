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

# list fnames for comparison
fnames = tolower(basename(flist))

OBS = EFF = vector('list', length(flist))
for(ii in seq_along(OBS)){
  
  # define ifile
  ifile = flist[[ii]]
  iname = fnames[[ii]]
  
  # add logic to skip raw files if edited files exist
  if(!grepl('edited', iname)){
    nname = gsub(pattern = 'raw', replacement = 'edited', x = iname)
    if(nname %in% fnames){
      inname = which(fnames == nname)
      message('Skipping raw data file: `', iname, '` because edited data exist here: `', fnames[inname], '`')
      OBS[[ii]] = data.frame()
      next
    }
  }
  
  # extract sightings and species codes
  obs = read_MDB(ifile, table_name = "Sightings")
  
  if(nrow(obs)>0){
    
    # check species codes
    # codes = as_tibble(tmp$MammalCodes)
    # 2 = right, 4 = blue, 5 = fin, 6 = sei, 9 = humpback,
    
    # isolate time strings
    tmp_time = substr(as.character(obs$EntryTime), 10, 18)
    tmp_date = substr(as.character(obs$Date), 0, 8)
    
    # fix formats
    if('InitLatitude' %in% colnames(obs)){
      obs$EntryLatitude = obs$InitLatitude
      obs$EntryLongitude = obs$InitLongitude
      levs = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH')
      labs = c('fin','right','sei','humpback','blue')
      labs = c('fin','right','sei','humpback','blue')
    } else if('InitLat' %in% colnames(obs)){
      obs$EntryLatitude = obs$InitLat
      obs$EntryLongitude = obs$InitLong
      levs = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH')
      labs = c('fin','right','sei','humpback','blue')
    } else {
      levs = c('2','4','5','6','9')
      labs = c('right','blue','fin','sei','humpback')
    }
    
    # format
    obs = obs %>%
      transmute(
        time = with_tz(as.POSIXct(paste0(tmp_date, ' ', tmp_time), format = '%m/%d/%y %H:%M:%S', tz = 'America/New_York'), tz = 'UTC'),
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
    obs$species = factor(obs$species, levels = levs, labels = labs)
    
    # fix calves number
    obs$calves[obs$calves == -9] = NA
  } else {
    obs = config_observations(data.frame())
  }
  # store obs
  OBS[[ii]] = obs
  
  # extract tracks
  eff = read_MDB(ifile, table_name = "SurveyTrack")
  
  # isolate time strings
  tmp_time = substr(as.character(eff$Time), 10, 18)
  tmp_date = substr(as.character(eff$Date), 0, 8)
  
  # format
  eff = eff %>%
    transmute(
      time = with_tz(as.POSIXct(paste0(tmp_date, ' ', tmp_time), format = '%m/%d/%y %H:%M:%S', tz = 'America/New_York'), tz = 'UTC'),
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
  EFF[[ii]] = eff
}

# collapse data
observations = bind_rows(OBS)
effort = bind_rows(EFF)

# save
saveRDS(observations, file = obs_file)
saveRDS(effort, file = eff_file)
