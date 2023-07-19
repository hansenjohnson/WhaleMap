## combine ##
# combine all obs and eff data

# functions
source('R/functions.R')

# effort ------------------------------------------------------------------

# list track files
tracks_list = list.files('data/interim', pattern = 'eff', full.names = T)

# read in files
TRK = vector('list', length(tracks_list))
for(ii in seq_along(tracks_list)){
  # get data
  TRK[[ii]] = readRDS(tracks_list[[ii]])
}

# flatten list
tracks = suppressWarnings(bind_rows(TRK))

# remove duplicates
# tracks = tracks[which(!duplicated(tracks)),]

# config tracks
tracks = config_tracks(tracks)

# fix source
tracks$source[is.na(tracks$source)] = 'WhaleMap'

# save
saveRDS(tracks, 'data/processed/effort.rds')

# observations ------------------------------------------------------------

# list obs files
obs_list = list.files('data/interim', pattern = 'obs', full.names = T)

# read in files
OBS = vector('list', length(obs_list))
for(ii in seq_along(obs_list)){
  # get data
  OBS[[ii]] = readRDS(obs_list[[ii]])
}

# combine
obs = suppressWarnings(bind_rows(OBS))

# remove duplicates
# obs = obs[!duplicated(obs[,c('lat', 'lon', 'date', 'time', 'species', 'number')]),]

# select only focal species, and reset factor levels
obs = obs[obs$species %in% c('right', 'fin', 'sei', 'humpback', 'blue'),]
obs$species = factor(obs$species)

# round position to reasonable number of digits
obs$lat = round(obs$lat,4)
obs$lon = round(obs$lon,4)

# configure observations
obs = config_observations(obs)

# rename score categories
obs$score[obs$score == 'detected'] = 'definite acoustic'
obs$score[obs$score == 'possibly detected'] = 'possible acoustic'
obs$score[obs$score == 'sighted'] = 'definite visual'
obs$score[obs$score == 'possibly sighted'] = 'possible visual'
obs$score = factor(obs$score, levels = c('definite acoustic', 'possible acoustic', 'possible visual', 'definite visual'))

# fix source
obs$source[is.na(obs$source)] = 'WhaleMap'

# save
saveRDS(obs, 'data/processed/observations.rds')

# names -------------------------------------------------------------------

# select names (for app filtering)
name_choices = as.character(unique(tracks$name))

# save
save(name_choices, file = 'data/processed/names.rda')
