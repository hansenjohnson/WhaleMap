# process and save all 2018 cwi sightings and tracklines

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2018_neaq_cwi/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('functions/config_data.R')
source('functions/subsample_gps.R')

# read in spp and obs keys
spp_key = read.csv(paste0(data_dir, '/species_key.csv'))

# list data files
flist = list.files(data_dir, pattern = '*CWI-V.csv$', full.names = T)

TRK = list()
SIG = list()
for(i in seq_along(flist)){
  
  # read in data
  tmp = read.csv(flist[i])
  
  # wrangle time
  tmp$time = as.POSIXct(tmp$Time, tz = 'UTC', usetz = T)
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # add deployment metadata
  tmp$platform = 'vessel'
  tmp$name = 'jdmartin'
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
  TRK[[i]] = do.call(rbind.data.frame, EFF)
  
  # sightings ---------------------------------------------------------------
  
  # take only sightings
  sig = droplevels(tmp[which(as.character(tmp$SPECCODE)!=""),])
  
  # get lat lons
  sig$lat = sig$LAT...SIGHTINGS
  sig$lon = sig$LONG...SIGHTINGS
  
  # get number of individuals
  sig$number = sig$NUMBER...SIGHTINGS
  
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
saveRDS(tracks, paste0(output_dir, '2018_cwi_jdmartin_tracks.rds'))

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = do.call(rbind.data.frame, SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, paste0(output_dir, '2018_cwi_jdmartin_sightings.rds'))
