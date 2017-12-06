# extract observation data (sightings/detections) as a csv

# read in data
obs = readRDS('data/processed/observations.rds')

# include only right whales in 2017
obs = subset(obs, obs$year==2017 & obs$species == 'right')

# export
write.csv(obs, '2017_narw_observations.csv', row.names = F)