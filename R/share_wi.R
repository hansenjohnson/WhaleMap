## share_wi ##
# extract track and observation data for Whale Insight

# input -------------------------------------------------------------------

# these are the output files generated
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
message('NOTE - sending all data since Jan 1 2024 until DFO has archived 2024 data')
t0 = as.Date('2024-01-01')
# t0 = as.Date(paste0(year(Sys.Date()),'-01-01'))

# read and subset tracks
trk = readRDS('data/processed/effort.rds') %>%
  dplyr::filter(date >= t0 & !is.na(lat) & !is.na(lon) & !(source %in% c('WhaleInsight', 'NARWC'))) %>%
  remove_dfo_ids()

# read and subset observations
obs = readRDS('data/processed/observations.rds') %>%
  dplyr::filter(date >= t0 & !is.na(lat) & !is.na(lon) & !(source %in% c('WhaleInsight', 'NARWC'))) %>%
  remove_dfo_ids()

# create a folder to write the files to
d_name <- dirname(trk_file)

if (!dir.exists(d_name)) {
  dir.create(d_name, recursive = T)
}

# save
write.csv(x = trk, file = trk_file, row.names = FALSE)
write.csv(x = obs, file = obs_file, row.names = FALSE)
