## proc_wm ##
# process old WhaleMap data (not submitted to NARWC)

source('R/functions.R')

d0 = as.Date('2017-01-01')
d1 = as.Date('2021-12-31')

# read and format obs
obs = readRDS('data/raw/wm/observations.rds') %>%
  filter(date >= d0 & date <= d1 & !is.na(lat) & !is.na(lon) & source == 'WhaleMap' & platform != 'slocum') %>%
  subset_canadian()

# read and format tracks
trk = readRDS('data/raw/wm/tracks.rds') %>%
  filter(date >= d0 & date <= d1 & !is.na(lat) & !is.na(lon) & platform != 'slocum') %>%
  subset_canadian()

# save
saveRDS(obs, file = 'data/interim/wm_obs.rds')
saveRDS(trk, file = 'data/interim/wm_eff.rds')
