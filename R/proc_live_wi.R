## proc_live_wi ##
# process and save live Canadian observation and effort data from WhaleInsight

# user input --------------------------------------------------------------

# input file
trk_ifile = 'data/raw/wi/live/trk_from_dfo.csv'
obs_ifile = 'data/raw/wi/live/obs_from_dfo.csv'

# output files
trk_ofile = 'data/interim/wi_live_eff.rds'
obs_ofile = 'data/interim/wi_live_obs.rds'

# process -----------------------------------------------------------------

source('R/functions.R')

# read in tracks
trk = read.csv(trk_ifile)

# config data types
tracks = config_tracks(trk)

# read in platform names from DCS
dl_file = 'data/raw/dcs/deployment_list.csv'
dl = read.csv(dl_file, stringsAsFactors = F)  
dcs = unique(str_split(dl$id, pattern = '_', n = 3, simplify = T)[,3])

# remove DCS platforms
tracks = tracks[!tracks$name %in% dcs,]

# fix source
if(nrow(tracks)>0){
  tracks$source = 'WhaleInsight'  
  tracks$platform = droplevels(tracks$platform)
}

# fix glider/buoy IDs
if(nrow(tracks)>0){
  if (("buoy" %in% levels(tracks$platform)) | ("slocum" %in% levels(tracks$platform))) {

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
  
  } else {
    # extract other tracks
    otrk = tracks %>% filter(!platform %in% c('buoy', 'slocum'))

    tracks = otrk
  }
}

# save
saveRDS(tracks, trk_ofile)

# read in obs
obs = read.csv(obs_ifile, stringsAsFactors = F)

# config data types
observations = config_observations(obs)

# remove DCS platforms
observations = observations[!observations$name %in% dcs,]

# fix source
if(nrow(observations)>0){
  observations$source = 'WhaleInsight'  
}

# save
saveRDS(observations, obs_ofile)
