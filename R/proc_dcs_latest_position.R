## proc_dcs_latest_position ##
# extract latest position(s) from live acoustic data

# input -------------------------------------------------------------------

dcs_file = 'data/interim/dcs_live_tracks.rds'
vik_file = 'data/interim/2019_dfo_viking_tracks.rds'
outfile = 'data/processed/dcs_live_latest_position.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# process -----------------------------------------------------------------

if(file.exists(dcs_file) & file.exists(vik_file)){
  
  # find latest detection data
  dcs = find_latest(dcs_file)
  vik = find_latest(vik_file)
  
  # combine
  latest = rbind.data.frame(dcs, vik, make.row.names = FALSE)
  
  # save
  saveRDS(latest, file = outfile)
  
} else if(file.exists(dcs_file)){
  
  latest = find_latest(dcs_file)
  
  # save
  saveRDS(latest, file = outfile)
  
} else if(file.exists(vik_file)){
  
  latest = find_latest(vik_file)
  
  # save
  saveRDS(latest, file = outfile)
  
} else {
  message('No live acoustic data detected')
  
  # remove latest position file
  if(file.exists(outfile)){
    file.remove(outfile)  
  }
}
