## proc_2021_neaq_aerial ##
# process and save all 2020/2021 neaq aerial sightings and tracklines

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2021_neaq_aerial/'

# directory for output
trk_ofile = 'data/interim/2021_neaq_aerial_tracks.rds'
obs_ofile = 'data/interim/2021_neaq_aerial_sightings.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH'),
  species = c('fin', 'right', 'sei', 'humpback', 'blue'))

# list data files
flist = list.files(data_dir, pattern = '\\d{8}_*.*.csv$',ignore.case = T, full.names = F, recursive = T)

# identify unique dates
dates = unique(substr(flist,1,8))

TRK = SIG = vector('list', length = length(dates))
for(ii in seq_along(dates)){
  
  # construct file names
  rfile = paste0(data_dir,dates[ii],'_RAW.csv')
  pfile = paste0(data_dir,dates[ii],'_URI.csv')
  
  # read in data
  if(file.exists(pfile)){
    tmp = read.csv(pfile)
    ifile=pfile
  } else if(file.exists(rfile)){
    tmp = read.csv(rfile)
    ifile=rfile
  } else {
    message('No file found for ',dates[ii])
    next
  }
  
  # wrangle time
  tmp$time = as.POSIXct(
    paste0(tmp$year,'-',tmp$month,'-',tmp$day,' ',sprintf('%06d', tmp$time)),
    format = '%Y-%m-%d %H%M%S', tz = 'America/New_York')
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # warning for time failure
  if(TRUE %in% is.na(tmp$time)){
    message('NA detected in timestamps of file ', ifile)
  }
  
  # add deployment metadata
  tmp$platform = 'plane'
  tmp$name = 'neaq'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # tracklines --------------------------------------------------------------
  
  # determine start/stop of effort segments
  i0 = which(tmp$legstage==1)
  i1 = which(tmp$legstage==5)
  
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
    itrk$lat = itrk$lat
    itrk$lon = itrk$long
    
    # get speed and altitude
    itrk$altitude = as.numeric(itrk$alt)
    itrk$speed = as.numeric(itrk$gpsspeed)
    
    # remove unused columns
    itrk = itrk[,c('time','lat','lon', 'altitude','speed','date','yday', 'year',  'platform', 'name', 'id')]
    
    # simplify
    itrk = subsample_gps(gps = itrk)
    
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
  sig = droplevels(tmp[which(as.character(tmp$speccode)!=""),])
  
  # extract data
  sig$lat = sig$lat
  sig$lon = sig$long
  sig$number = as.numeric(as.character(sig$number))
  sig$calves = as.numeric(as.character(sig$numcalf))
  
  # get score
  sig$score[which(sig$number>0)] = 'sighted'
  
  # find indecies of matching
  mind = match(table = spp_key$code, x = sig$speccode)
  
  # replace codes with species names
  sig$species = spp_key$species[mind]
  
  # drop unknown codes
  sig = sig[which(!is.na(sig$species)),]
  
  # keep important columns
  sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','calves','year','platform','name','id')]
  
  # add to the list
  SIG[[ii]] = sig
  
}

# prep track output -------------------------------------------------------

# combine all tracks
tracks = bind_rows(TRK)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, trk_ofile)

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = bind_rows(SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, obs_ofile)
