## proc_2018-08-04_dfo_twin_otter_error ##
# Correct sightings and effort from the DFO twin otter using backup GPS data

# user input --------------------------------------------------------------

# track files
tfile1 = 'data/raw/2018_whalemapdata/DFO_twin_otter/20180804/20180804a.gpx'
tfile2 = 'data/raw/2018_whalemapdata/DFO_twin_otter/20180804/20180804b.gpx'

# sightings file
sfile = 'data/raw/2018_whalemapdata/DFO_twin_otter/20180804/D180804final.sig'

# output file names
tofile = '2018-08-04_dfo_twin_otter_tracks.rds'
sofile = '2018-08-04_dfo_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

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

# extract track time/positon ----------------------------------------------------------

# read in track files
trk1 = readOGR(dsn = tfile1, layer="track_points", verbose = F)
trk2 = readOGR(dsn = tfile2, layer="track_points", verbose = F)

# convert to data frame
trk = rbind(as.data.frame(trk1),as.data.frame(trk2))

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
tracks = config_tracks(tracks)

# plot track
if(plot_tracks){
  plot_save_track(tracks, tfile1)
}

# save
saveRDS(tracks, paste0(output_dir, tofile))

# process sightings -------------------------------------------------------

# read in data (method below is slower but more robust to errors in gps file)
textLines = readLines(sfile)
counts = count.fields(textConnection(textLines), sep=",")
sig = read.table(text=textLines[counts == 21 & !is.na(counts)], header=FALSE, sep=",")

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
  sig$lat[i] = trk$lat[ind]
  sig$lon[i] = trk$lon[ind]
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
sig = config_observations(sig)

# save
saveRDS(sig, paste0(output_dir, sofile))

# verify ------------------------------------------------------------------

# plot(tracks$lon, tracks$lat, type = 'l', xlab = '', ylab = '')
# points(sig$lon[sig$species=='right'], sig$lat[sig$species=='right'], pch = 16, col = 'red')
