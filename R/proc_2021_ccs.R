## proc_2021_ccs ##
# process and save all 2020/2021 ccs sightings, tracklines, and opportunstic reports

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2021_ccs/aerial/'

# directory for output
trk_ofile = 'data/interim/2021_ccs_tracks.rds'
obs_ofile = 'data/interim/2021_ccs_sightings.rds'

# opportunistic input / output
opp_ifile = 'data/raw/2021_ccs/opportunistic/CCS_opp.csv'
opp_ofile = 'data/interim/2021_ccs_opportunistic_sightings.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH'),
  species = c('fin', 'right', 'sei', 'humpback', 'blue'))

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
  
  # save
  saveRDS(opp, opp_ofile)
  
}

# survey data -------------------------------------------------------------

# list data files
flist = list.files(data_dir, pattern = '\\d{8}_*.*_raw.csv$', full.names = T, recursive = T)

TRK = SIG = vector('list', length = length(flist))
if(length(flist)>0){
  for(ii in seq_along(flist)){
    
    # read in data
    tmp = read.csv(flist[ii])
    
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

# output ------------------------------------------------------------------

# combine all tracks
tracks = bind_rows(TRK)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, trk_ofile)

# combine all sightings
sightings = bind_rows(SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, obs_ofile)
