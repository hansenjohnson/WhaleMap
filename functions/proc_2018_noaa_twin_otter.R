## proc_2018_noaa_twin_otter ##
# Process gps and sightings data from NOAA Twin Otter survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_noaa_twin_otter/edit_data/'

# output file names
track_file = '2018_noaa_twin_otter_tracks.rds'
sighting_file = '2018_noaa_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('functions/config_data.R')
source('functions/subsample_gps.R')

# process -----------------------------------------------------------------

# list all flight directories
flist = list.dirs(data_dir, full.names = TRUE, recursive = FALSE)

TRK = list()
SIG = list()
for(i in seq_along(flist)){
  
  # determine flight dir
  idir = flist[i]
  
  # check for f_file
  f_file = list.files(idir, pattern = '^f_(\\d{6}).csv$', full.names = TRUE)
  
  # process f_file
  if(length(f_file)!=0){
    
    # read in data
    tmp = read.csv(f_file, stringsAsFactors = FALSE)
    
    # wrangle time
    tmp$time = as.POSIXct(tmp$DateTime, format = '%Y-%m-%d %H:%M:%S', tz = 'UTC', usetz = T)
    
    # try a different format if previous did not work
    if(is.na(tmp$time[1])){
      tmp$time = as.POSIXct(tmp$DateTime, format = '%m/%d/%Y %H:%M', tz = 'UTC', usetz = T)
    }
    
    # other time vars
    tmp$date = as.Date(tmp$time)
    tmp$yday = yday(tmp$time)
    tmp$year = year(tmp$time)
    
    # add deployment metadata
    tmp$platform = 'plane'
    tmp$name = 'noaa_twin_otter'
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    
    # extract lat/lon
    tmp$lat = tmp$LATITUDE
    tmp$lon = tmp$LONGITUDE
    
    # get speed and altitude
    tmp$altitude = tmp$ALTITUDE
    tmp$speed = tmp$SPEED
    
    # tracklines --------------------------------------------------------------
    
    # take important columns
    trk = tmp[,c('time','lat','lon', 'altitude','speed','date','yday', 'year',  'platform', 'name', 'id')]
    
    # re-order
    trk = trk[order(trk$time, decreasing = TRUE),]
    
    # simplify
    trk = subsample_gps(gps = trk)
    
    # combine all effort segments
    TRK[[i]] = trk
    
    # sightings ---------------------------------------------------------------
    
    # take only sightings
    sig = droplevels(tmp[which(as.character(tmp$SPCODE)!=""),])
    
    # get sighting number
    sig$number = sig$GROUP_SIZE
    
    # get score
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
    
    # drop unknown codes
    sig = sig[which(!is.na(sig$species)),]
    
    # right whale numbers
    eg = sig[sig$species=='right',]
    eg = eg[(!grepl('dup', eg$SIGHTING_COMMENTS) & 
                (grepl('ap',eg$SIGHTING_COMMENTS) | 
                   grepl('fin est no break', eg$SIGHTING_COMMENTS) | 
                   grepl('No right whales', eg$DateTime))),]
    
    # other whales
    noeg = sig[sig$species!='right',]
    
    # recombine all species
    sig = rbind.data.frame(eg,noeg)
    
    # keep important columns
    sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]
    
    # add to the list
    SIG[[i]] = sig
    
  } else {
    
    message('Using raw data (not f_file) in: \n', idir)
    
    # gps tracklines ----------------------------------------------------------
    
    # find gps file
    gps_file = list.files(idir, pattern = '.gps$', full.names = TRUE, recursive = TRUE)[1]
    
    # read in data (method below is slower but more robust to errors in gps file)
    textLines = readLines(gps_file)
    counts = count.fields(textConnection(textLines), sep=",")
    trk = read.table(text=textLines[counts == 7], header=FALSE, sep=",")
    
    # select and rename important columns
    trk = data.frame(trk$V1, trk$V3, trk$V2, trk$V4, trk$V6)
    colnames(trk) = c('time', 'lon', 'lat', 'speed', 'altitude')
    
    # remove columns without timestamp
    trk = trk[which(!is.na(trk$time)),]
    
    # add timestamp
    trk$time = as.POSIXct(trk$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
    
    # subsample (use default subsample rate)
    tracks = subsample_gps(gps = trk)
    
    # add metadata
    tracks$date = as.Date(tracks$time)
    tracks$yday = yday(tracks$date)
    tracks$year = year(tracks$date)
    tracks$platform = 'plane'
    tracks$name = 'noaa_twin_otter'
    tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
    
    # add to list
    TRK[[i]] = tracks
    
    # sig sightings -----------------------------------------------------------
    
    # find sig file
    sig_files = list.files(idir, pattern = '.sig$', full.names = TRUE, recursive = TRUE)
    
    iSIG = list()
    for(j in seq_along(sig_files)){
      
      # skip empty files
      if(file.size(sig_files[j]) == 0) next
      
      # read in data
      sig = read.table(sig_files[j], sep = ',')
      
      # assign column names
      colnames(sig) = c('transect', 'unk1', 'unk2', 'time', 'observer', 'declination', 'species', 'number', 'confidence', 'bearing', 'unk5', 'unk6', 'comments', 'side', 'lat', 'lon', 'calf', 'unk7', 'unk8', 'unk9', 'unk10')
      
      # remove final estimates
      sig = sig[!grepl(pattern = 'fin est', x = sig$comments, ignore.case = TRUE),]
      
      # if they exist, only include actual positions
      if(nrow(sig[grepl(pattern = 'ap', x = sig$comments, ignore.case = TRUE),])>0){
        sig = sig[grepl(pattern = 'ap', x = sig$comments, ignore.case = TRUE),]
      }
      
      # remove columns without timestamp
      sig = sig[which(!is.na(sig$time)),]
      
      # add timestamp
      sig$time = as.POSIXct(sig$time, format = '%d/%m/%Y %H:%M', tz="UTC", usetz=TRUE)
      
      # add metadata
      sig$date = as.Date(sig$time)
      sig$yday = yday(sig$date)
      sig$year = year(sig$date)
      sig$score = 'sighted'
      sig$platform = 'plane'
      sig$name = 'noaa_twin_otter'
      sig$id = paste(sig$date, sig$platform, sig$name, sep = '_')
      
      # initialize species column
      sig$sp_code = as.character(sig$species)
      sig$species = NA
      
      # add species identifiers
      sig$sp_code = toupper(sig$sp_code)
      sig$species[sig$sp_code == 'EG'] = 'right'
      sig$species[sig$sp_code == 'MN'] = 'humpback'
      sig$species[sig$sp_code == 'BB'] = 'sei'
      sig$species[sig$sp_code == 'BP'] = 'fin'
      sig$species[sig$sp_code == 'BA'] = 'minke'
      sig$species[sig$sp_code == 'BM'] = 'blue'
      
      # drop unknown codes
      sig = sig[which(!is.na(sig$species)),]
      
      # keep important columns
      sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]
      
      # add to list
      iSIG[[j]] = sig
    }
    
    # combine multiple sightings file
    SIG[[i]] = do.call(rbind.data.frame, iSIG)
  }
}

# prep track output -------------------------------------------------------

# combine all tracks
tracks = do.call(rbind.data.frame, TRK)

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, track_file))

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = do.call(rbind.data.frame, SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, paste0(output_dir, sighting_file))

