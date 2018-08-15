## proc_2018_dfo_twin_otter_gps_error.R ##
# process tracks and sightings from DFO twin otter when errors occur in primary GPS
# this script 1) identifies flights with bad gps (empty .gps files), 2) matches timestamps in .gpx files 
# and .sig files to determine sightings positions.

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/DFO_twin_otter/'

# output directory
output_dir = 'data/interim/'

# output file names
tofile = '2018_dfo_twin_otter_gps_error_tracks.rds'
sofile = '2018_dfo_twin_otter_gps_error_sightings.rds'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
library(readxl, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')
source('functions/subsample_gps.R')
source('functions/plot_save_track.R')
source('functions/on_server.R')

# plot tracks?
plot_tracks = !on_server()

# process -----------------------------------------------------------------

# find all gps files
flist = list.files(data_dir, pattern = '.gps$', full.names = T, recursive = T)

# find flights with gps errors
flts = flist[which(file.size(flist) == 0)]

# isolate flight directories
fdirs = dirname(flts)

TRACKS = list()
SIG = list()
for(i in seq_along(fdirs)){
  
  # process tracks ----------------------------------------------------------
  
  # list gps files
  trks = list.files(fdirs[i], pattern = '.gpx', full.names = T, recursive = T)
  
  # skip if empty
  if(length(trks)==0){
    message('No gpx file available to correct primary gps error for flight: ', trks[i])
    next
  }
  
  # read and combine gps files
  trklist = list()
  for(j in seq_along(trks)){
    trklist[[j]] = as.data.frame(readOGR(dsn = trks[j], layer="track_points", verbose = F))
  }
  
  # flatten and combine
  trk = do.call(rbind, trklist)
  
  # dummy variable for speed
  trk$speed = NA
  
  # select and rename important columns
  trk = data.frame(trk$time, trk$coords.x1, trk$coords.x2, trk$speed, trk$ele)
  colnames(trk) = c('time', 'lon', 'lat', 'speed', 'altitude')
  
  # remove columns without timestamp
  trk = trk[which(!is.na(trk$time)),]
  
  # add timestamp
  trk$time = as.POSIXct(trk$time, format = '%Y/%m/%d %H:%M:%OS', tz = 'UTC')
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = trk)
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'plane'
  tracks$name = 'dfo_twin_otter'
  tracks$id = paste0(tracks$date, '_plane_dfo_twin_otter')
  
  # config flight data
  TRACKS[[i]] = config_tracks(tracks)
  
  # plot track
  if(plot_tracks){
    plot_save_track(tracks, trks[1])
  }
  
  # process sightings -------------------------------------------------------
  
  # list sightings files
  sigs = list.files(fdirs[i], pattern = '.sig$', full.names = T, recursive = T)
  
  # read in files
  siglist = list()
  for(k in seq_along(sigs)){
    # textLines = readLines(sigs[k])
    # counts = count.fields(textConnection(textLines), sep=",")
    # siglist[[k]] = read.table(text=textLines[counts == 21 & !is.na(counts)], header=FALSE, sep=",")
    siglist[[k]] = read.csv(sigs[k])
  }
  # flatten and combine
  sig = do.call(rbind, siglist)
  
  # assign column names
  colnames(sig) = c('transect', 'unk1', 'unk2', 'time', 'observer', 'declination', 'species', 'number', 'unk4', 'bearing', 'unk5', 'unk6', 'comments', 'side', 'lat', 'lon', 'audio', 'unk7', 'photo', 'unk8', 'unk9')
  
  # remove columns without timestamp
  sig = sig[which(!is.na(sig$time)),]
  
  # add timestamp
  sig$time = as.POSIXct(sig$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
  
  # fix blank species rows
  sig$species = as.character(sig$species)
  sig$species[sig$species==""] = NA
  
  # remove columns without species
  sig = sig[which(!is.na(sig$species)),]
  
  # add species identifiers
  sig$species = toupper(sig$species)
  sig$species[sig$species == 'EG'] = 'right'
  sig$species[sig$species == 'MN'] = 'humpback'
  sig$species[sig$species == 'BB'] = 'sei'
  sig$species[sig$species == 'BP'] = 'fin'
  sig$species[sig$species == 'FS'] = 'fin/sei'
  sig$species[sig$species == 'BA'] = 'minke'
  sig$species[sig$species == 'BM'] = 'blue'
  sig$species[sig$species == 'UW'|sig$species == 'LGWH'] = 'unknown whale'
  
  # pull positions from track file by timestamp association
  for(i in 1:nrow(sig)){
    
    # find index of nearest timestamp
    ind = which.min(abs(sig$time[i]-trk$time))  
    
    # print time difference warning
    diff = sig$time[i]-trk$time[ind]
    if(abs(diff)>60*5){
      message('Warning! Time difference of: ', diff, ' seconds') 
    }
    
    # pull position from trk file
    sig$lat[i] = as.numeric(trk$lat[ind])
    sig$lon[i] = as.numeric(trk$lon[ind])
  }
  
  # remove duplicate sightings
  sig = sig[!grepl('resight', tolower(as.character(sig$comments))),]
  
  # select important columns
  sig = sig[,c('time', 'lat', 'lon', 'species', 'number')]
  
  # add sightings metadata
  sig$date = as.Date(sig$time)
  sig$yday = yday(sig$date)
  sig$year = year(sig$date)
  sig$score = 'sighted'
  sig$platform = 'plane'
  sig$name = 'dfo_twin_otter'
  sig$id = paste(sig$date, sig$platform, sig$name, sep = '_')
  
  # remove strange characters in 'number' column
  sig$number = gsub(pattern = '\\+', replacement = '', x = sig$number)
  sig$number = gsub(pattern = '\`', replacement = '', x = sig$number)
  sig$number = as.numeric(sig$number)
  
  # config flight data
  SIG[[i]] = config_observations(sig)
  
  # # verify
  # plot(tracks$lon, tracks$lat, xlab = '', ylab = '', type = 'l')
  # points(sig$lon, sig$lat, pch = 16, col = 'blue')
  # points(sig$lon[sig$species=='right'], sig$lat[sig$species=='right'], 
  #       pch = 16, col = 'red')
}

# flatten data
final_sig = do.call(rbind, SIG)
final_trk = do.call(rbind, TRACKS)

# save
saveRDS(final_sig, paste0(output_dir, sofile))
saveRDS(final_trk, paste0(output_dir, tofile))
