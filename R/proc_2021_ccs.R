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

if(file.exists(ifile)){
  
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
    tmp$name = tolower(strsplit(basename(flist[ii]),'_')[[1]][2])
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    
    # tracklines --------------------------------------------------------------
    
    # determine start/stop of effort segments
    i0 = which(tmp$LEGSTAGE==1)
    i1 = which(tmp$LEGSTAGE==5)
    
    # enter off-effort automatically
    if(length(i1)==0){
      i1 = nrow(tmp)
    }
    
    # enter off-effort automatically
    if(length(i0)!=length(i1)){
      i1 = c(i1,nrow(tmp))
    }
    
    if(length(i0) != length(i1)){
      i0 = 1
      i1 = nrow(tmp)
      message('Could not match on/off effort lines in: ', flist[i])
      message('Plotting uncorrected effort data...')
    }
    
    # fill in leg stage info for each effort segment
    EFF = vector('list', length = length(i0))
    for(j in 1:length(i0)){
      
      # effort segment
      itrk = tmp[i0[j]:i1[j],]
      
      # fix lat lons
      itrk$lat = itrk$TrkLatitude
      itrk$lon = itrk$TrkLongitude
      
      # get speed and altitude
      itrk$altitude = as.numeric(gsub(pattern = ' m', replacement = '', x = itrk$TrkAltitude..ft.))
      itrk$speed = as.numeric(gsub(pattern = ' kts', replacement = '', x = itrk$TrkDist..nm.))
      
      # remove unused columns
      itrk = itrk[,c('time','lat','lon', 'altitude','speed','date','yday', 'year',  'platform', 'name', 'id')]
      
      # simplify
      itrk = subsample_gps(gps = itrk, tol = 0.00025)
      
      # duplicate last row, and replace pos with NA's for plotting
      itrk = rbind(itrk, itrk[nrow(itrk),])
      itrk$lat[nrow(itrk)] = NA
      itrk$lon[nrow(itrk)] = NA
      
      # add to list
      EFF[[j]] = itrk
    }
    
    # combine all effort segments
    TRK[[ii]] = bind_rows(EFF)
    
    # sightings ---------------------------------------------------------------
    
    # take only sightings
    sig = droplevels(tmp[which(as.character(tmp$SPECCODE)!=""),])
    
    # extract data
    sig$lat = sig$LATITUDE
    sig$lon = sig$LONGITUDE
    sig$number = as.numeric(as.character(sig$NUMBER))
    sig$calves = as.numeric(as.character(sig$NUMCALF))
    
    # get score
    sig$score[which(sig$number>0)] = 'sighted'
    
    # find indecies of matching
    mind = match(table = spp_key$code, x = sig$SPECCODE)
    
    # replace codes with species names
    sig$species = spp_key$species[mind]
    
    # drop unknown codes
    sig = sig[which(!is.na(sig$species)),]
    
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
