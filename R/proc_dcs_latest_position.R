## proc_dcs_latest_position ##
# extract latest position(s) from live acoustic data

# input -------------------------------------------------------------------

dcs_file = 'data/interim/dcs_live_eff.rds'
outfile = 'data/processed/dcs_live_latest_position.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# process -----------------------------------------------------------------

if(file.exists(dcs_file)){
  
  latest = find_latest(dcs_file)
  
  # save
  saveRDS(latest, file = outfile)
  
} else {
  message('No live acoustic data detected')
  
  # remove latest position file
  if(file.exists(outfile)){
    file.remove(outfile)  
  }
}
