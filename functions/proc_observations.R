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
  
  # combine
  if(i==1){
    obs = iobs
  } else {
    obs = rbind(obs, iobs) # add to list 
  }
}

# remove duplicates
obs = obs[which(!duplicated(obs)),]

# select only focal species
obs = obs[obs$species %in% c('right', 'fin', 'sei', 'humpback', 'blue'),]

# rename score categories
levels(obs$score) = c('definite visual', 'possible visual', 'definite acoustic', 'possible acoustic')
obs$score = droplevels(obs$score)

# save
saveRDS(obs, 'data/processed/observations.rds')