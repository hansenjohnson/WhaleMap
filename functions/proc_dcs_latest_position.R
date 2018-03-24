# extract latest position(s) from live glider data

# user input --------------------------------------------------------------

infile = 'data/interim/dcs_live_tracks.rds'

outfile = 'data/processed/dcs_live_latest_position.rds'

# process -----------------------------------------------------------------

if(file.exists(infile)){
  # read in data
  tracks = readRDS(infile)
  
  # # remove NAs
  # dep = tracks[complete.cases(tracks),]
  
  # split tracks by deployment
  dep = split(tracks, tracks$id)
  
  # determine latest observation from each deployment
  latest = lapply(dep, function(x){
    x[nrow(x),]
  })
  
  # flatten list
  latest = do.call(rbind,latest)
  
  # save output
  saveRDS(latest, file = outfile)
  
} else {
  message('No live dcs data detected')
  
  # remove latest position file
  if(file.exists(outfile)){
    file.remove(outfile)  
  }
  
}


