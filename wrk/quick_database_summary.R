## quick_database_summary ##

library(tidyverse)

# read in tracks and observations
trk = readRDS('data/processed/tracks.rds')
obs = readRDS('data/processed/observations.rds')

# dcs summary -------------------------------------------------------------

# slocum
tmp = subset(trk, platform == 'slocum')
n_slocum = length(unique(tmp$id))

# buoy
tmp = subset(trk, platform == 'buoy')
n_buoy = length(unique(tmp$id))

# number of detections
n_detections = obs %>%
  filter(score == 'definite acoustic' & species == 'right') %>%
  count(date) %>%
  summarise(detection_days = sum(n))

# flight summary ----------------------------------------------------------

n_flights = trk %>%
  filter(year == 2018 & platform == 'plane') %>%
  summarize(flights = length(unique(id)))
