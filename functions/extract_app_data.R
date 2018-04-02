# extract app data

# track data --------------------------------------------------------------

# read in data
tracks = readRDS('data/processed/tracks.rds')

# subset in time
# tracks = tracks[tracks$year %in% c(2015,2016,2017),]
tracks = tracks[tracks$year %in% c(2017),]

# subset in space
# tracks = tracks[tracks$lon <= -57 & tracks$lon >= -66,]
# tracks = tracks[tracks$lat <= 51.5 & tracks$lat >= 45.5,]

# split by platform
# vis_tracks = tracks[tracks$platform %in% c('vessel','plane'),]
# dcs_tracks = tracks[tracks$platform %in% c('slocum'),]

# write to files
# write.csv(vis_tracks, file = 'visual_survey_tracks.csv', row.names = F)
# write.csv(dcs_tracks, file = 'acoustic_survey_tracks.csv', row.names = F)
write.csv(tracks, file = 'data/extracted/2017_tracks.csv', row.names = F)

# observation data --------------------------------------------------------

# read in data
obs = readRDS('data/processed/observations.rds')

# subset in time
# obs = obs[obs$year %in% c(2015,2016,2017),]
obs = obs[obs$year %in% c(2017),]

# subset in space
# obs = obs[obs$lon <= -57 & obs$lon >= -66,]
# obs = obs[obs$lat <= 51.5 & obs$lat >= 45.5,]

# subset by species
obs = obs[obs$species == 'right',]

# split by platform
# vis_obs = obs[obs$platform %in% c('vessel','plane'),]
# dcs_obs = obs[obs$platform %in% c('slocum'),]

# write to files
# write.csv(vis_obs, file = 'visual_survey_obs.csv', row.names = F)
# write.csv(dcs_obs, file = 'acoustic_survey_obs.csv', row.names = F)
write.csv(obs, file = 'data/extracted/2017_obs.csv', row.names = F)

# check -------------------------------------------------------------------

# plot(vis_tracks$lon, vis_tracks$lat, col = 'darkslategray', type = 'l')
# lines(dcs_tracks$lon, dcs_tracks$lat, col = 'blue')
# 
# points(vis_obs$lon, vis_obs$lat, pch=16, col = 'black')
# points(dcs_obs$lon, dcs_obs$lat, pch=16, col = 'blue')

plot(tracks$lon, tracks$lat, col = 'darkslategray', type = 'l')
points(obs$lon, obs$lat, pch=16, col = 'blue')

summary(vis_tracks)
