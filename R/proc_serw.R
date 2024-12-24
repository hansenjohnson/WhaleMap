## proc_serw ##
# process and save all aerial sightings and tracklines from the SEUS

# user input --------------------------------------------------------------

# warnings
quiet = TRUE

# directory to look for files
data_dir = 'data/raw/serw/'

# directory for output
trk_ofile = 'data/interim/serw_eff.rds'
obs_ofile = 'data/interim/serw_obs.rds'

# process -----------------------------------------------------------------

source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH'),
  species = c('fin', 'right', 'sei', 'humpback', 'blue'))
sco_key = data.frame(
  code = c(3,2,1),
  score = c('sighted', 'possibly sighted', 'possibly sighted'))

# list data files
flist = list.files(data_dir, pattern = '\\d{8}.*csv$',ignore.case = T, full.names = T, recursive = T)

TRK = SIG = vector('list', length = length(flist))
for(ii in seq_along(flist)){
  
  # isolate file
  ifile = flist[ii]
  
  # read in data
  tmp = read.csv(ifile, stringsAsFactors = FALSE)
  
  # check colnames
  if(colnames(tmp)[1] != "Date"){
    message('Error detected in column names in file: ', ifile)
    message('Skipping...')
    next
  }
  
  # wrangle time
  tmp$date = as.Date(tmp$Date, format = "%m/%d/%Y %H:%M:%S")
  times = sapply(strsplit(tmp$Time,split = ' '), FUN = function(x){x[2]})
  tmp$time = as.POSIXct(paste0(tmp$date, ' ', times), format = '%Y-%m-%d %H:%M:%S', tz = 'UTC')
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  tmp$source = 'WhaleMap'
  
  # warning for time failure
  if(TRUE %in% is.na(tmp$time) & !quiet){
    message('NA detected in timestamps of file ', ifile)
  }
  
  # add deployment metadata
  tmp$name = substr(basename(ifile), start = 0, stop = 4)
  tmp$platform = 'plane'
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
    if(!quiet){
      message('Could not match on/off effort lines in: ', ifile)
      message('Plotting uncorrected effort data...')  
    }
  }
  
  # fill in leg stage info for each effort segment
  EFF = vector('list', length = length(i0))
  for(j in 1:length(i0)){
    
    # effort segment
    itrk = tmp[i0[j]:i1[j],]
    
    # fix lat lons
    itrk$lat = itrk$Latitude
    itrk$lon = itrk$Longitude
    
    # get speed and altitude
    itrk$altitude = ifelse(!is.null(itrk$ALT), as.numeric(itrk$ALT), NA)
    itrk$speed = ifelse(!is.null(itrk$SPEED), as.numeric(itrk$SPEED), NA)
    
    # remove unused columns
    itrk = itrk[,c('time','lat','lon','altitude','speed','date','yday','year','platform','name','id','source')]
    
    # simplify
    itrk = subsample_gps(gps = itrk, tol = 0.0001)
    
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
  sig$lat = sig$Latitude
  sig$lon = sig$Longitude
  sig$number = as.numeric(as.character(sig$NUMBER))
  sig$calves = as.numeric(as.character(sig$NUMCALF))
  
  # find indicies of matching species and replace
  spp_ind = match(table = spp_key$code, x = sig$SPECCODE)
  sig$species = spp_key$species[spp_ind]
  
  # find indicies of matching species and replace
  sco_ind = match(table = sco_key$code, x = sig$IDREL)
  sig$score = sco_key$score[sco_ind]
  
  # drop unknown codes
  sig = sig[which(!is.na(sig$species) & !is.na(sig$score)),]
  
  # keep important columns
  sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','calves','year','platform','name','id','source')]
  
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
