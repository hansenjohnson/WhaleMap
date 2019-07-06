## proc_2019_neaq ##
# process and save all 2019 neaq/cwi sightings and tracklines

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2019_neaq/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'MIWH', 'SEWH', 'HUWH', 'HAPO', 'GRSE', 'PIWH'),
  species = c('fin', 'right', 'minke', 'sei', 'humpback', 'harbor porpoise', 'grey seal','pilot whale'))

# list data files
flist = list.files(data_dir, pattern = '\\d{4}-\\d{2}-\\d{2}-*', full.names = T)

TRK = SIG = vector('list', length = length(flist))
for(i in seq_along(flist)){
  
  # read in data
  tmp = read.csv(flist[i])
  
  # determine vessel and timezone
  isrv = strsplit(as.character(flist[i]), split = '-')[[1]][4]
  if(isrv == 'NEA'){
    itz = 'America/New_York'
    ivs = 'nereid'
  } else {
    itz = 'America/Halifax'
    ivs = 'jdmartin'
  }
  
  # wrangle time
  tmp$time = as.POSIXct(tmp$Time, tz = itz, usetz = T)
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # add deployment metadata
  tmp$platform = 'vessel'
  tmp$name = ivs
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # tracklines --------------------------------------------------------------
  
  # determine start/stop of effort segments
  i0 = which(tmp$LEGSTAGE...ENVIRONMENTALS==1)
  i1 = which(tmp$LEGSTAGE...ENVIRONMENTALS==5)
  
  # enter off-effort automatically
  if(length(i1)==0){
    i1 = nrow(tmp)
  }
  
  # enter off-effort automatically
  if(length(i0)!=length(i1)){
    i1 = c(i1,nrow(tmp))
  }
  
  if(length(i0) < length(i1)){
    i0 = 1
    i1 = nrow(tmp)
    message('Could not match on/off effort lines in: ', flist[i])
    message('Plotting uncorrected effort data...')
  }
  
  # fill in leg stage info for each effort segment
  EFF = list()
  for(j in 1:length(i0)){
    
    # effort segment
    itrk = tmp[i0[j]:i1[j],]
    
    # fix lat lons
    itrk$lat = itrk$TrkLatitude
    itrk$lon = itrk$TrkLongitude
    
    # get speed and altitude
    itrk$altitude = as.numeric(gsub(pattern = ' m', replacement = '', x = itrk$TrkAltitude))
    itrk$speed = as.numeric(gsub(pattern = ' kts', replacement = '', x = itrk$PlatformSpeed))
    
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
  TRK[[i]] = bind_rows(EFF)
  
  # sightings ---------------------------------------------------------------
  
  # take only sightings
  sig = droplevels(tmp[which(as.character(tmp$SPECCODE)!=""),])
  
  # find data columns by name
  ilat = which(colnames(sig) %in% c('LATITUDE', 'LAT...SIGHTINGS'))
  ilon = which(colnames(sig) %in% c('LONGITUDE', 'LONG...SIGHTINGS'))
  inum = which(colnames(sig) %in% c('NUMBER', 'NUMBER...SIGHTINGS'))
  
  # extract data
  sig$lat = sig[,ilat]
  sig$lon = sig[,ilon]
  sig$number = sig[,inum]
  
  # get score
  sig$score[which(sig$number>0)] = 'sighted'
  
  # find indecies of matching
  mind = match(table = spp_key$code, x = sig$SPECCODE)
  
  # replace codes with species names
  sig$species = spp_key$species[mind]
  
  # drop unknown codes
  sig = sig[which(!is.na(sig$species)),]
  
  # keep important columns
  sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]
  
  # add to the list
  SIG[[i]] = sig
  
}

# prep track output -------------------------------------------------------

# combine all tracks
tracks = do.call(rbind.data.frame, TRK)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, '2019_neaq_tracks.rds'))

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = bind_rows(SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, paste0(output_dir, '2019_neaq_sightings.rds'))
