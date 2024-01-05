## proc_nefsc_vessel ##
# define function to process sightings and tracklines from NEFSC vessel(s)

# setup -------------------------------------------------------------------

source('R/functions.R')

# process gpx -------------------------------------------------------------

proc_nefsc_vessel = function(data_dir, trk_ofile, obs_ofile){
  
  # list gpx tracks
  flist = list.files(data_dir, pattern = '\\d{8}_*.*_Garmin_Trackline.gpx$', ignore.case = T, full.names = T, recursive = T)
  
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
  
  # process sightings -------------------------------------------------------
  
  # list sightings data files
  olist = list.files(data_dir, pattern = "*sighttotal.csv$", recursive = T, full.names = T)
  
  if(length(olist)>=0){
    OBS = vector('list', length = length(olist))
    for(io in seq_along(olist)){
      
      # read in tracks
      tmp = read.csv(olist[io], stringsAsFactors = F)
      
      # convert lat / lon
      tmp$lat = tmp$EntryLatitude
      tmp$lon = tmp$EntryLongitude
      
      # wrangle time
      tmp$date = as.Date(tmp$Date, format = '%d-%b-%y')
      tmp$time = as.POSIXct(paste0(tmp$date, ' ', tmp$EntryTime), format = '%Y-%m-%d %H:%M:%S', tz = 'UTC')
      tmp$yday = yday(tmp$time)
      tmp$year = year(tmp$time)
      tmp$source = 'WhaleMap'
      
      # add deployment metadata
      tmp$name = tolower(substr(basename(olist[io]), 0,3))
      tmp$platform = 'vessel'
      tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
      
      # add sightings data
      tmp$species = NA
      tmp$species[tmp$SpeciesCode == 'HUWH'] = 'humpback'
      tmp$species[tmp$SpeciesCode == 'RIWH'] = 'right'
      tmp$species[tmp$SpeciesCode == 'FIWH'] = 'fin'
      tmp$species[tmp$SpeciesCode == 'SEWH'] = 'sei'
      
      tmp$number = tmp$GroupSize
      tmp$calves = tmp$Calves
      tmp$calves[tmp$Calves < 0] = NA
      
      tmp$score = NA
      tmp$score[tmp$Confidence == 'certain'] = 'sighted'
      tmp$score[tmp$Confidence %in% c('probably', 'not sure')] = 'possibly sighted'
      
      # configure
      tmp = config_observations(tmp)
      OBS[[io]] = tmp[!is.na(tmp$species),]
    }
    
    # combine
    obs = bind_rows(OBS)
    
  } else {
    
    # data frame empty
    obs = data.frame()
  }
  
  # save --------------------------------------------------------------------
  
  # format
  observations = config_observations(obs)
  tracks = config_tracks(trk)
  
  # save tracks
  saveRDS(tracks, trk_ofile)
  
  # save sightings
  saveRDS(observations, obs_ofile)
}