## share_wi ##
# extract track and observation data for Whale Insight

# input -------------------------------------------------------------------

trk_file = 'shared/dfo-whalemap/trk_for_dfo.csv'
obs_file = 'shared/dfo-whalemap/obs_for_dfo.csv'

# setup -------------------------------------------------------------------

source('R/functions.R')

# remove dfo/tc ids
remove_dfo_ids = function(obs){
  ids = unique(obs$id)
  good_ids = ids[!grepl(pattern = 'dfo|tc', x = ids)]
  subset(obs, id %in% good_ids)
}

# process -----------------------------------------------------------------

# define start time
t0 = as.Date('2022-01-01')

# read and subset tracks
trk = readRDS('data/processed/effort.rds') %>%
  dplyr::filter(date >= t0 & !is.na(lat) & !is.na(lon) & source != 'WhaleInsight') %>%
  remove_dfo_ids()

# read and subset observations
obs = readRDS('data/processed/observations.rds') %>%
  dplyr::filter(date >= t0 & !is.na(lat) & !is.na(lon) & source != 'WhaleInsight') %>%
  remove_dfo_ids()

# save
write.csv(x = trk, file = trk_file, row.names = FALSE)
write.csv(x = obs, file = obs_file, row.names = FALSE)
