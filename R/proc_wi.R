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
