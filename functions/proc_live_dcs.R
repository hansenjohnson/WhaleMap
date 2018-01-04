# process and save all live dcs (glider, buoy, etc) deployment tracklines and detections

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/dcs/live/'

# directory for output
output_dir = 'data/interim/'

# track file
track_fname = 'dcs_live_tracks.rds'

# detection file
det_fname = 'dcs_live_detections.rds'

# process -----------------------------------------------------------------

# determine if there are any live missions
flist = list.files(path = data_dir, full.names = T)

if(length(flist)==0){
  
  # if there are no raw files, remove interim files
  message('No live dcs data detected')
  
  # list interim files  
  tfile = paste0(output_dir, track_fname)
  dfile = paste0(output_dir, det_fname)
  
  # remove track file
  if(file.exists(tfile)){
    file.remove(tfile)  
  }
  
  # remove detection file
  if(file.exists(dfile)){
    file.remove(dfile)  
  }
  
} else {
  
  # if there are live raw data files, process live dcs
  
  # read in function
  source('functions/proc_dcs.R')
  
  # process data
  proc_dcs(data_dir = data_dir, 
           output_dir = output_dir, 
           det_fname = det_fname, 
           track_fname = track_fname,
           ext = '-live')
}



