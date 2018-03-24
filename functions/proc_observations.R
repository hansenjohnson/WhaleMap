## proc_observations ##
# combine all observations

# functions
source('functions/config_data.R')

# list sightings files
obs_list = list.files('data/interim', pattern = 'sightings|detections', full.names = T)

# read in files
for(i in seq_along(obs_list)){
  
  # get data
  iobs = readRDS(obs_list[[i]])
  # iobs = config_observations(iobs)
  
  if(i==1){
    obs = iobs
  }
  
  # add to list
  obs = rbind(obs, iobs)
}

# remove duplicates
obs = obs[which(!duplicated(obs)),]

# save
saveRDS(obs, 'data/processed/observations.rds')