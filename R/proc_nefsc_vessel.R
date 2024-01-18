## proc_nefsc_vessel ##
# define function to process sightings and tracklines from NEFSC vessel(s)

# setup -------------------------------------------------------------------

source('R/functions.R')

# process gpx -------------------------------------------------------------

proc_nefsc_vessel_effort = function(data_dir){
  
  # list gpx tracks
  flist = list.files(data_dir, pattern = '*_Trackline.gpx$', ignore.case = T, full.names = T, recursive = T)
  
  if(length(flist)>0){
    
    # extract GPS data
    TRK = vector('list', length = length(flist))
    for(ii in seq_along(flist)){
      
      # isolate file
      ifile = flist[ii]
      
      # read in GPX data
      tmp = read_GPX(ifile)
      
      # wrangle time
      tmp$time = as.POSIXct(tmp$time, format = '%Y-%m-%d %H:%M:%S', tz = 'UTC')
      tmp$date = as.Date(tmp$time)
      tmp$yday = yday(tmp$time)
      tmp$year = year(tmp$time)
      tmp$source = 'WhaleMap'
      
      # add deployment metadata
      tmp$name = tolower(strsplit(basename(ifile), '_')[[1]][2])
      tmp$platform = 'vessel'
      tmp$id = paste(min(tmp$date, na.rm = T), tmp$platform, tmp$name, sep = '_')
      
      # simplify
      tmp = subsample_gps(tmp)
      
      # configure
      TRK[[ii]] = config_tracks(tmp)
    }
    
    # combine
    trk = bind_rows(TRK)
    
  } else {
    
    # create empty data frame
    trk = data.frame()
    
  }
  
  # format tracks
  tracks = config_tracks(trk)
  
  return(tracks)
}
