## proc_observations ##
# generate processed/observations.rds from all interim sightings or detection data

# functions
source('functions/config_data.R')

# list sightings files
obs_list = list.files('data/interim', pattern = 'sightings|detections', full.names = T)

# read in files
OBS = list()
for(i in seq_along(obs_list)){
  OBS[[i]] = readRDS(obs_list[[i]])
}

# merge files
obs = Reduce(function(x, y) merge(x, y, all=TRUE), OBS)

# adjust column types
obs = config_observations(obs)

# remove duplicates
obs = obs[which(!duplicated(obs)),]

# save
saveRDS(obs, 'data/processed/observations.rds')
