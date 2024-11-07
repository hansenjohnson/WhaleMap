## proc_dmr ##
# process and save all dmr vessel/aerial sightings and effort

# user input --------------------------------------------------------------

# directory to look for data files
a_data_dir = 'data/raw/medmr/Aerial/'
v_data_dir = 'data/raw/medmr/Vessel/'

# directory for output
trk_ofile = 'data/interim/medmr_eff.rds'
obs_ofile = 'data/interim/medmr_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH'),
  species = c('fin', 'right', 'sei', 'humpback', 'blue'))

# aerial ------------------------------------------------------------------

# list data files
a_flist = list.files(a_data_dir, pattern = '*.csv$', full.names = T, recursive = T)

TRK = SIG = vector('list', length = length(a_flist))
if(length(a_flist)>0){
  for(ii in seq_along(a_flist)){
    
    # read in data
    tmp = read.csv(a_flist[ii])
    
    # colnames in caps
    colnames(tmp) = toupper(colnames(tmp))
    
    # wrangle time
    tmp$time = as.POSIXct(tmp[,grep(pattern = "TRKTIME..", x = colnames(tmp))], format = '%Y-%m-%dT%H:%M:%S', tz = 'America/New_York')
    tmp$time = with_tz(tmp$time, tzone = 'UTC')
    tmp$date = as.Date(tmp$time)
    tmp$yday = yday(tmp$time)
    tmp$year = year(tmp$time)
    
    # add deployment metadata
    tmp$platform = 'plane'
    tmp$name = 'medmr'
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    
    # tracklines --------------------------------------------------------------
    
    # fill LEGSTAGE
    trk = tmp
    
    # fix lat lons
    trk$lat = trk$TRKLATITUDE
    trk$lon = trk$TRKLONGITUDE
    
    # get speed and altitude
    trk$altitude = trk$TRKALTITUDE..FT.
    trk$speed = trk$PLATFORMSPEED..KTS.
    
    # add source
    trk$source = 'WhaleMap'
    
    # remove unused columns
    trk = trk[,c('time','lat','lon', 'altitude','speed','date','yday','year','platform','name','id','source')]
    
    # store track
    TRK[[ii]] = subsample_gps(gps = trk)
    
    # sightings ---------------------------------------------------------------
    
    # take only sightings
    sig = droplevels(tmp[which(as.character(tmp$SPECCODE...SIGHTINGS)!=""),])
    
    if(nrow(sig)>0 & TRUE %in% (spp_key$code %in% sig$SPECCODE...SIGHTINGS)){
      
      # extract data
      sig$lat = sig$TRKLATITUDE
      sig$lon = sig$TRKLONGITUDE
      sig$number = as.numeric(sig$NUMBER...SIGHTINGS)
      sig$calves = as.numeric(sig$NUMCALF...SIGHTINGS)
      
      # find indicies of matching
      mind = match(table = spp_key$code, x = sig$SPECCODE...SIGHTINGS)
      
      # replace codes with species names
      sig$species = spp_key$species[mind]
      
      # drop unknown codes
      sig = sig[which(!is.na(sig$species)),]
      
      # get scores
      sig$score = "possibly sighted"
      sig$score[which(sig$IDREL...SIGHTINGS %in% c(3,2))] = 'sighted'
      
      # add source
      sig$source = 'WhaleMap'
      
      # keep important columns
      sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','calves','year','platform','name','id','source')]
      
    } else {
      sig = config_observations(data.frame())
    }
    
    # add to the list
    SIG[[ii]] = sig
    
  }
}

# combine 
a_tracks = bind_rows(TRK)
a_sightings = bind_rows(SIG)

# configure
a_tracks = config_tracks(a_tracks)
a_sightings = config_observations(a_sightings)

# vessel ------------------------------------------------------------------

# list data files
v_flist = list.files(v_data_dir, pattern = '*.csv$', full.names = T, recursive = T)

TRK = SIG = vector('list', length = length(v_flist))
if(length(v_flist)>0){
  for(ii in seq_along(v_flist)){
    
    # read in data
    tmp = read.csv(v_flist[ii])
    
    # colnames in caps
    colnames(tmp) = toupper(colnames(tmp))
    
    # wrangle time
    tmp$time = as.POSIXct(tmp[,grep(pattern = "TRKTIME..", x = colnames(tmp))], format = '%Y-%m-%dT%H:%M:%S', tz = 'America/New_York')
    tmp$time = with_tz(tmp$time, tzone = 'UTC')
    tmp$date = as.Date(tmp$time)
    tmp$yday = yday(tmp$time)
    tmp$year = year(tmp$time)
    
    # add deployment metadata
    tmp$platform = 'vessel'
    tmp$name = 'medmr'
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    
    # tracklines --------------------------------------------------------------
    
    # fill LEGSTAGE
    trk = tmp
    
    # fix lat lons
    trk$lat = trk$TRKLATITUDE
    trk$lon = trk$TRKLONGITUDE
    
    # get speed and altitude
    trk$altitude = NA
    trk$speed = NA
    
    # add source
    trk$source = 'WhaleMap'
    
    # remove unused columns
    trk = trk[,c('time','lat','lon', 'altitude','speed','date','yday','year','platform','name','id','source')]
    
    # store track
    TRK[[ii]] = subsample_gps(gps = trk)
    
    # sightings ---------------------------------------------------------------
    
    # take only sightings
    sig = droplevels(tmp[which(as.character(tmp$SPECCODE...SIGHTING)!=""),])
    
    if(nrow(sig)>0 & TRUE %in% (spp_key$code %in% sig$SPECCODE...SIGHTING)){
      
      # extract data
      sig_lat_col = which(colnames(sig) == "SGT.LAT...SIGHTING"|colnames(sig) == "S_LAT...SIGHTING")
      sig_lon_col = which(colnames(sig) == "SGT.LON...SIGHTING"|colnames(sig) == "S_LONG...SIGHTING")
      number_col = which(colnames(sig) == "COUNT...SIGHTING"|colnames(sig) == "NUMBER...SIGHTING")
      sig$lat = sig[,sig_lat_col]
      sig$lon = sig[,sig_lon_col]
      sig$number = as.numeric(as.character(sig[,number_col]))
      sig$calves = sig$NUMCALF...SIGHTING
      
      # find indicies of matching
      mind = match(table = spp_key$code, x = sig$SPECCODE...SIGHTING)
      
      # replace codes with species names
      sig$species = spp_key$species[mind]
      
      # drop unknown codes
      sig = sig[which(!is.na(sig$species)),]
      
      # get scores
      sig$score = "possibly sighted"
      sig$score[which(sig$IDREL...SIGHTING %in% c(3,2))] = 'sighted'
      
      # add source
      sig$source = 'WhaleMap'
      
      # keep important columns
      sig = sig[,c('time','lat','lon','date','yday','species','score','number','calves','year','platform','name','id','source')]
      
    } else {
      sig = config_observations(data.frame())
    }
    
    # add to the list
    SIG[[ii]] = sig
    
  }
}

# combine 
v_tracks = bind_rows(TRK)
v_sightings = bind_rows(SIG)

# configure
v_tracks = config_tracks(v_tracks)
v_sightings = config_observations(v_sightings)

# combine ------------------------------------------------------------------

# combine all tracks
tracks = bind_rows(a_tracks, v_tracks)

# save
saveRDS(tracks, trk_ofile)

# combine all sightings
sightings = bind_rows(a_sightings, v_sightings)

# save
saveRDS(sightings, obs_ofile)
