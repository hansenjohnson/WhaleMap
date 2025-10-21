## proc_live_nerw ##
# Process live gps and sightings data from NOAA Twin Otter survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/nerw/live/'

# output file names
track_file = 'data/interim/nerw_live_eff.rds'
sighting_file = 'data/interim/nerw_live_obs.rds'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(readxl))
source('R/functions.R')

# process -----------------------------------------------------------------

# list all flight directories
flist = list.files(data_dir,pattern = '^f_', full.names = TRUE, recursive = FALSE)

# list output column names for sightings
cnames = c('time','lat','lon','date','yday','species','score','number','calves','year','platform','name','id')

TRK = SIG = vector('list', length = length(flist))
for(i in seq_along(flist)){
  
  # isolate file
  ifile = flist[i]
  
  # determine file extension
  ext = file_ext(ifile)
  
  # read in data
  if(ext == 'csv'){
    tmp = read.csv(ifile, stringsAsFactors = FALSE)
  } else {
    tmp = read_excel(ifile, guess_max = 4e3)
  }
  
  # find time column
  tcol = grep(pattern = 'datetime', x = colnames(tmp), ignore.case = TRUE)
  
  # rename
  colnames(tmp)[tcol] = 'DateTime'
  
  # wrangle time
  tmp$time = as.POSIXct(as.character(tmp$DateTime), 
                        format = '%Y-%m-%d %H:%M:%S', tz = 'America/New_York', usetz = T)
  
  # try a different format if previous did not work
  if(is.na(tmp$time[1])){
    tmp$time = as.POSIXct(as.character(tmp$DateTime), 
                          format = '%m/%d/%Y %H:%M', tz = 'America/New_York', usetz = T)
  }
  
  # convert timezone
  tmp$time = with_tz(tmp$time, tzone = 'UTC')
  
  # other time vars
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # add deployment metadata
  tmp$platform = 'plane'
  tmp$name = gsub(pattern = " ", replacement = "_", x = tolower(tmp$PLANE))
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # extract lat/lon
  tmp$lat = tmp$LATITUDE
  tmp$lon = tmp$LONGITUDE
  
  # get speed and altitude
  tmp$altitude = tmp$ALTITUDE
  tmp$speed = tmp$SPEED
  
  # tracklines --------------------------------------------------------------
  
  # take important columns
  trk = tmp[,c('time','lat','lon', 'altitude','speed','date','yday', 'year','platform', 'name', 'id')]
  
  # re-order
  trk = trk[order(trk$time, decreasing = TRUE),]
  
  # simplify (with condition for odd file behavior)
  if(basename(ifile) == "f_250211.xlsx"){
    trk = subsample_gps(gps = trk, n = 30, simplify = F)  
  } else {
    trk = subsample_gps(gps = trk)  
  }
  
  # combine all effort segments
  TRK[[i]] = trk
  
  # sightings ---------------------------------------------------------------
  
  # take only sightings
  sig = droplevels(tmp[which(as.character(tmp$SPCODE)!=""),])
  
  if(nrow(sig)>0){
    
    # get sighting number
    sig$number = sig$GROUP_SIZE
    
    # get score
    sig$score = NA
    sig$score[sig$ID_RELIABILITY>0] = 'sighted'
    
    # determine species
    sig$species = NA
    sig$SPCODE = toupper(as.character(sig$SPCODE))
    sig$species[sig$SPCODE == 'RIWH'] = 'right'
    sig$species[sig$SPCODE == 'HUWH'] = 'humpback'
    sig$species[sig$SPCODE == 'SEWH'] = 'sei'
    sig$species[sig$SPCODE == 'FIWH'] = 'fin'
    sig$species[sig$SPCODE == 'MIWH'] = 'minke'
    sig$species[sig$SPCODE == 'BLWH'] = 'blue'
    
    # determine calves
    sig$calves = sig$CALVES
    
    # drop unknown codes
    sig = sig[which(!is.na(sig$species)),]
    
    # right whale numbers
    eg = sig[sig$species=='right',]
    eg = eg[(!grepl('dup', eg$SIGHTING_COMMENTS) & 
               (grepl('ap',eg$SIGHTING_COMMENTS) | 
                  grepl('fin est no break', eg$SIGHTING_COMMENTS) | 
                  grepl('No right whales', eg$DateTime))),]
    
    # blue whales
    bw = sig[sig$species=='blue',]
    bw = bw[(!grepl('dup', bw$SIGHTING_COMMENTS) & 
               grepl('ap', bw$SIGHTING_COMMENTS)),]
    
    # other whales
    ows = sig[!sig$species %in% c('right','blue'),]
    
    # recombine all species
    sig = rbind.data.frame(eg,bw,ows)
    
    # keep important columns
    sig = sig[,cnames]
    
  } else {
    
    # make empty data frame
    sig = data.frame(matrix(ncol = length(cnames), nrow = 0))
    colnames(sig) = cnames
    sig = config_observations(sig)
  }
  
  # add to the list
  SIG[[i]] = sig
  
}

# prep track output -------------------------------------------------------

# combine all tracks
tracks = bind_rows(TRK)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, track_file)

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = bind_rows(SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, sighting_file)
