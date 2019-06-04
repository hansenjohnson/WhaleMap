## proc_observations ##
# combine all observations

# functions
source('R/functions.R')

# list sightings files
obs_list = list.files('data/interim', pattern = 'sightings|detections', full.names = T)

# read in files
OBS = vector('list', length(obs_list))
for(ii in seq_along(obs_list)){
  # get data
  OBS[[ii]] = readRDS(obs_list[[ii]])
}

# combine
obs = suppressWarnings(bind_rows(OBS))

# remove duplicates
obs = obs[!duplicated(obs[,c('lat', 'lon', 'date', 'species', 'number')]),]

# select only focal species, and reset factor levels
obs = obs[obs$species %in% c('right', 'fin', 'sei', 'humpback', 'blue'),]
obs$species = factor(obs$species)

# round position to reasonable number of digits
obs$lat = round(obs$lat,4)
obs$lon = round(obs$lon,4)

# configure observations
obs = config_observations(obs)

# rename score categories
obs$score = factor(obs$score, levels = c('detected', 'possibly detected', 'possibly sighted', 'sighted'), 
       labels = c('definite acoustic', 'possible acoustic', 'possible visual', 'definite visual'))

# save
saveRDS(obs, 'data/processed/observations.rds')