## proc_wi ##
# process and save Canadian observation and effort data from WhaleInsight

# user input --------------------------------------------------------------

# input file
trk_ifile = 'data/raw/wi/trk_from_dfo.csv'
obs_ifile = 'data/raw/wi/obs_from_dfo.csv'

# output files
trk_ofile = 'data/interim/wi_eff.rds'
obs_ofile = 'data/interim/wi_obs.rds'

# process -----------------------------------------------------------------

source('R/functions.R')

# read in tracks
trk = read.csv(trk_ifile)

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

# read in obs
obs = read.csv(obs_ifile, stringsAsFactors = F)

# config data types
observations = config_observations(obs)

# fix source
if(nrow(observations)>0){
  observations$source = 'WhaleInsight'  
}

# save
saveRDS(observations, obs_ofile)
