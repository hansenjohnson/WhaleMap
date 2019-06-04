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
obs = bind_rows(OBS)

# remove duplicates
obs = obs[!duplicated(obs[,c('lat', 'lon', 'date', 'species', 'number')]),]

# select only focal species, and reset factor levels
obs = obs[obs$species %in% c('right', 'fin', 'sei', 'humpback', 'blue'),]
obs$species = factor(obs$species)

# round position to reasonable number of digits
obs$lat = round(obs$lat,4)
obs$lon = round(obs$lon,4)

# rename score categories
levels(obs$score) = c('definite visual', 'possible visual', 'definite acoustic', 'possible acoustic')

# save
saveRDS(obs, 'data/processed/observations.rds')