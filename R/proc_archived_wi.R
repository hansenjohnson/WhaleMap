## proc_archived_wi ##
# process and save archived Canadian observation and effort data from WhaleInsight

# user input --------------------------------------------------------------

# input directory
idir = 'data/raw/wi/archived/'

# output files
trk_ofile = 'data/interim/wi_archived_eff.rds'
obs_ofile = 'data/interim/wi_archived_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# effort ------------------------------------------------------------------

# find track files
trk_ifiles = list.files(path = idir, pattern = 'trk_from_dfo.csv', 
                        include.dirs = T, recursive = T, full.names = T)

# read in tracks
TRK = vector('list', length = length(trk_ifiles))
for(ii in seq_along(TRK)){
  TRK[[ii]] = read.csv(trk_ifiles[[ii]])
}

# flatten
trk = bind_rows(TRK)

# config data types
tracks = config_tracks(trk)

# fix source
if(nrow(tracks)>0){
  tracks$source = 'WhaleInsight'  
}

# fix glider/buoy IDs
if(nrow(tracks)>0){
  
  # filter tracks and arrange
  itrk = tracks %>% filter(platform %in% c('buoy', 'slocum')) %>%
    arrange(platform, name, time)
  
  # define unique index
  itrk$ind = cumsum(c(0,diff(as.numeric(as.factor(paste0(itrk$platform, itrk$name))))))
  
  # redefine ID
  itrk = itrk %>% group_by(platform, name, ind) %>%
    mutate(id = paste0(min(date), '-', unique(platform), '-', unique(name))) %>%
    ungroup() %>%
    select(-ind)
  
  # extract other tracks
  otrk = tracks %>% filter(!platform %in% c('buoy', 'slocum'))
  
  # combine
  tracks = bind_rows(itrk,otrk)
}

# save
saveRDS(tracks, trk_ofile)

# observations ------------------------------------------------------------

# find obs files
obs_ifiles = list.files(path = idir, pattern = 'obs_from_dfo.csv', 
                        include.dirs = T, recursive = T, full.names = T)

# read in tracks
OBS = vector('list', length = length(obs_ifiles))
for(ii in seq_along(OBS)){
  OBS[[ii]] = read.csv(obs_ifiles[[ii]], stringsAsFactors = F)
}

# flatten
obs = bind_rows(OBS)

# config data types
observations = config_observations(obs)

# fix source
if(nrow(observations)>0){
  observations$source = 'WhaleInsight'  
}

# save
saveRDS(observations, obs_ofile)
