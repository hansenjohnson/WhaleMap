## proc_ccs ##
# process and save all ccs sightings, tracklines, and opportunistic reports

# user input --------------------------------------------------------------

# directory to look for files
a_data_dir = 'data/raw/ccs/aerial/'
v_data_dir = 'data/raw/ccs/vessel/'
opp_ifile = 'data/raw/ccs/opportunistic/CCS_opp.csv'

# directory for output
trk_ofile = 'data/interim/ccs_eff.rds'
obs_ofile = 'data/interim/ccs_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH'),
  species = c('fin', 'right', 'sei', 'humpback', 'blue'))

v_spp_key = data.frame(
  code = c('Right Whale, Eg'),
  species = c('right'))

# survey data -------------------------------------------------------------

# list data files
a_flist = list.files(a_data_dir, pattern = '\\d{8}_*.*_raw.csv$', full.names = T, recursive = T)

TRK = SIG = vector('list', length = length(a_flist))
if(length(a_flist)>0){
  for(ii in seq_along(a_flist)){
    
    # read in data
    tmp = read.csv(a_flist[ii])
    
    # wrangle time
    tmp$time = as.POSIXct(tmp[,grep('time..e', tolower(colnames(tmp)))], 
                          format = '%Y-%m-%dT%H:%M:%S', tz = 'America/New_York')
    tmp$date = as.Date(tmp$time)
    tmp$yday = yday(tmp$time)
    tmp$year = year(tmp$time)
    
    # add deployment metadata
    tmp$platform = 'plane'
    tmp$name = 'ccs'
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    
    # tracklines --------------------------------------------------------------
    
    # fill LEGSTAGE
    trk = tmp %>%
      fill(LEGTYPE, .direction = 'down')
    
    # fix lat lons
    trk$lat = trk$TrkLatitude
    trk$lon = trk$TrkLongitude
    
    # get speed and altitude
    trk$altitude = as.numeric(gsub(pattern = ' m', replacement = '', x = trk$TrkAltitude..ft.))
    trk$speed = as.numeric(gsub(pattern = ' kts', replacement = '', x = trk$TrkDist..nm.))
    
    # set to NA for plotting
    lt0 = which(trk$LEGTYPE == 0)
    trk$lon[lt0] = NA
    trk$lat[lt0] = NA
    
    # remove unused columns
    trk = trk[,c('time','lat','lon', 'altitude','speed','date','yday', 'year',  'platform', 'name', 'id')]
    
    # store track
    TRK[[ii]] = trk
    
    # sightings ---------------------------------------------------------------
    
    # take only sightings
    sig = droplevels(tmp[which(as.character(tmp$SPECCODE)!=""),])
    
    # extract data
    sig$lat = sig$LATITUDE
    sig$lon = sig$LONGITUDE
    sig$number = suppressWarnings(as.numeric(as.character(sig$NUMBER)))
    sig$calves = suppressWarnings(as.numeric(as.character(sig$NUMCALF)))
    
    # find indicies of matching
    mind = match(table = spp_key$code, x = sig$SPECCODE)
    
    # replace codes with species names
    sig$species = spp_key$species[mind]
    
    # drop unknown codes
    sig = sig[which(!is.na(sig$species)),]
    
    # drop zero numbers (used by ccs to relocate dups)
    sig = sig[!is.na(sig$number),]
    sig = sig[sig$number>0,]
    
    # get scores
    sig$score[sig$IDREL %in% c(3)] = 'sighted'
    sig$score[sig$IDREL %in% c(1,2)] = 'possibly sighted'
    sig = sig[which(!is.na(sig$score)),]
    
    # keep important columns
    sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','calves','year','platform','name','id')]
    
    # add to the list
    SIG[[ii]] = sig
    
  }
}

# combine all tracks
a_tracks = bind_rows(TRK)

# config data types
a_tracks = config_tracks(a_tracks)

# combine all sightings
a_sightings = bind_rows(SIG)

# config data types
a_sightings = config_observations(a_sightings)

# vessel ------------------------------------------------------------------

# list data files
v_flist = list.files(v_data_dir, pattern = '\\d{8}_Integrated Export.csv$', full.names = T, recursive = T)

TRK = SIG = vector('list', length = length(v_flist))
if(length(v_flist)>0){
  for(ii in seq_along(v_flist)){
    
    # read in data
    tmp = read.csv(v_flist[ii])
    
    # wrangle time
    tmp$time = as.POSIXct(tmp[,grep('time..e', tolower(colnames(tmp)))], 
                          format = '%Y-%m-%dT%H:%M:%S', tz = 'America/New_York')
    tmp$date = as.Date(tmp$time)
    tmp$yday = yday(tmp$time)
    tmp$year = year(tmp$time)
    
    # add deployment metadata
    tmp$platform = 'vessel'
    tmp$name = 'ccs'
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    
    # tracklines --------------------------------------------------------------
    
    # fill LEGSTAGE
    trk = tmp
    
    # fix lat lons
    trk$lat = trk$TrkLatitude
    trk$lon = trk$TrkLongitude
    
    # get speed and altitude
    trk$altitude = NA
    trk$speed = NA
    
    # remove unused columns
    trk = trk[,c('time','lat','lon', 'altitude','speed','date','yday', 'year',  'platform', 'name', 'id')]
    
    # store track
    TRK[[ii]] = trk
    
    # sightings ---------------------------------------------------------------
    
    # take only sightings
    sig = droplevels(tmp[which(as.character(tmp$Species)!=""),])
    
    if(nrow(sig)>0){
      
      # extract data
      sig$lat = sig$Latitude
      sig$lon = sig$Longitude
      sig$number = as.numeric(as.character(sig$Min.Count))
      sig$calves = ifelse(tolower(sig$Calf.present) == 'yes', 1, 0)
      
      # find indicies of matching
      mind = match(table = v_spp_key$code, x = sig$Species)
      
      # replace codes with species names
      sig$species = v_spp_key$species[mind]
      
      # drop unknown codes
      sig = sig[which(!is.na(sig$species)),]
      
      # get scores
      sig$score = 'sighted'  
      
      # keep important columns
      sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','calves','year','platform','name','id')]
      
    } else {
      sig = config_observations(data.frame())
    }
    
    # add to the list
    SIG[[ii]] = sig
    
  }
}

# combine all tracks
v_tracks = bind_rows(TRK)

# config data types
v_tracks = config_tracks(v_tracks)

# combine all sightings
v_sightings = bind_rows(SIG)

# config data types
v_sightings = config_observations(v_sightings)

# opportunistic data ------------------------------------------------------

if(file.exists(opp_ifile)){
  
  # read in data
  opp = read.csv(opp_ifile)
  
  # wrangle time
  time = paste0(opp$year,'-', sprintf("%02d", opp$month), '-', sprintf("%02d", opp$day), ' ', opp$time)
  opp$time = as.POSIXct(time, format = '%Y-%m-%d %H:%M:%S', tz = 'UTC', usetz=TRUE)
  
  # wrangle date
  opp$date = as.Date(opp$time)
  opp$yday = yday(opp$date)
  opp$year = year(opp$date)
  
  # wrangle text
  opp$verified = tolower(opp$verified)
  opp$photos = tolower(opp$photos)
  
  # lookup species 
  mind = match(table = spp_key$code, x = opp$species)
  opp$species = spp_key$species[mind]
  
  # drop unknown codes
  opp = opp[which(!is.na(opp$species)),]
  
  # score
  opp$score = 'possibly sighted'
  opp$score[opp$verified == 'yes'] = 'sighted'
  
  # convert number to numeric
  opp$number = as.numeric(opp$number)
  
  # convert calves to numeric
  opp$calves = as.numeric(opp$numcalf)
  
  # clean lat lons
  opp = clean_latlon(opp)
  
  # add metadata
  opp$name = 'CCS_report'
  opp$platform = 'opportunistic'
  opp$id = paste0(opp$date, '_', opp$platform, '_', opp$name)
  
  # config data types
  opp = config_observations(opp)
  
} else {
  opp = config_observations(data.frame())
}

# output ------------------------------------------------------------------

# combine all tracks
tracks = bind_rows(a_tracks, v_tracks)

# add source
tracks$source = 'WhaleMap'

# save
saveRDS(tracks, trk_ofile)

# combine all sightings
sightings = bind_rows(a_sightings, v_sightings, opp)

# add source
sightings$source = 'WhaleMap'

# save
saveRDS(sightings, obs_ofile)
