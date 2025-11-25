## share_sarbo ##
# extract track and observation data for SARBO app

# input -------------------------------------------------------------------

# these are the output files generated
trk_file = 'shared/sarbo/effort.csv'
obs_file = 'shared/sarbo/observations.csv'

# setup -------------------------------------------------------------------

source('R/functions.R')
source('global.R')

fdir = dirname(trk_file)
if(!dir.exists(fdir)){dir.create(fdir, recursive = T)}

# process -----------------------------------------------------------------

# define start time
t0 = as.Date(paste0(year(Sys.Date()),'-01-01'))

# read and subset tracks
trk = readRDS('data/processed/effort.rds') %>%
  dplyr::filter(date >= t0 & !is.na(lat) & !is.na(lon) & !(source %in% c('WhaleInsight', 'NARWC')) & !(name %in% hidden_platforms))

# read and subset observations
obs = readRDS('data/processed/observations.rds') %>%
  dplyr::filter(date >= t0 & !is.na(lat) & !is.na(lon) & !(source %in% c('WhaleInsight', 'NARWC')) & !(name %in% hidden_platforms))

# save
write.csv(x = trk, file = trk_file, row.names = FALSE)
write.csv(x = obs, file = obs_file, row.names = FALSE)
