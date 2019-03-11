# extract latest position(s) from live glider data

# user input --------------------------------------------------------------

infile = 'data/interim/dcs_live_tracks.rds'
jasco_file = 'data/interim/2018_jasco_tracks.rds'
outfile = 'data/processed/dcs_live_latest_position.rds'

# process -----------------------------------------------------------------

if(file.exists(infile)){
  
  # read in data
  tracks = readRDS(infile)
  
  # remove NAs
  tracks = tracks[!is.na(tracks$lat),]
  
  # split tracks by deployment
  dep = split(tracks, tracks$id)
  
  # determine latest observation from each deployment
  latest = lapply(dep, function(x){
    x[nrow(x),]
  })
  
  # flatten list
  latest = do.call(rbind,latest)
  
  # add jasco position
  if(file.exists(jasco_file)){
    
    # read jasco file
    jasco = readRDS(jasco_file)
    
    # isolate latest jasco position
    jmax = jasco[jasco$time==max(jasco$time, na.rm = TRUE),]
    
    # add to latest data frame
    latest = rbind.data.frame(latest, jmax, make.row.names = FALSE)
    
  }
  
  # save output
  saveRDS(latest, file = outfile)
  
} else {
  message('No live dcs data detected')
  
  # remove latest position file
  if(file.exists(outfile)){
    file.remove(outfile)  
  }
  
}


