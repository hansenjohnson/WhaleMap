## proc_nefsc ##
# process old nefsc data

source('R/functions.R')

d0 = as.Date('2014-01-01')
d1 = as.Date('2021-12-31')

# read and format obs
obs = readRDS('data/raw/wm/observations.rds') %>%
  filter(date >= d0 & date <= d1 & !is.na(lat) & !is.na(lon) & name == 'noaa_twin_otter')

# read and format tracks
trk = readRDS('data/raw/wm/tracks.rds') %>%
  filter(date >= d0 & date <= d1 & !is.na(lat) & !is.na(lon) & name == 'noaa_twin_otter')

# save
saveRDS(obs, file = 'data/interim/nefsc_obs.rds')
saveRDS(trk, file = 'data/interim/nefsc_eff.rds')
