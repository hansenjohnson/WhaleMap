# process all data for use in app

# process each platform ---------------------------------------------------

# dcs (gliders, buoys, etc)
source('functions/proc_dcs.R')

# noaa (noaa plane) 2015
source('functions/proc_noaa_2015.R')

# shelagh (cwi boat) 2016
source('functions/proc_shelagh_2016.R')

# 2017 tracklines
source('functions/proc_noaa_tracks_2017.R')
source('functions/proc_shelagh_tracks_2017.R')

# 2017 sightings
source('functions/proc_sightings_2017.R')

# combine and save observations -------------------------------------------

# read in data
det = readRDS('data/interim/dcs_detections.rds')
noaa15_sig = readRDS('data/interim/2015_noaa_sightings.rds')
noaa17_sig = readRDS('data/interim/2017_noaa_sightings.rds')
shelagh16_sig = readRDS('data/interim/2016_shelagh_sightings.rds')
shelagh17_sig = readRDS('data/interim/2017_shelagh_sightings.rds')

# merge 
obs = Reduce(function(x, y) merge(x, y, all=TRUE), list(det, 
                                                        noaa15_sig,
                                                        noaa17_sig,
                                                        shelagh16_sig,
                                                        shelagh17_sig))

# adjust column types
obs$year = as.factor(obs$year)
obs$id = as.factor(obs$id)
obs$platform = as.factor(obs$platform)
obs$species = as.factor(obs$species)
obs$score = as.factor(obs$score)
obs$yday = as.numeric(obs$yday)
obs$lat = as.numeric(obs$lat)
obs$lon = as.numeric(obs$lon)

# save
saveRDS(obs, 'data/processed/observations.rds')

# combine and save tracklines ---------------------------------------------

# read in data
dcs = readRDS('data/interim/dcs_tracks.rds')
noaa15_tracks = readRDS('data/interim/2015_noaa_tracks.rds')
noaa17_tracks = readRDS('data/interim/2017_noaa_tracks.rds')
shelagh16_tracks = readRDS('data/interim/2016_shelagh_tracks.rds')
shelagh17_tracks = readRDS('data/interim/2017_shelagh_tracks.rds')

# merge 
tracks = Reduce(function(x, y) merge(x, y, all=TRUE), list(dcs, 
                                                           noaa15_tracks,
                                                           noaa17_tracks, 
                                                           shelagh16_tracks, 
                                                           shelagh17_tracks))

# sort by time (important for plotting)
tracks = tracks[order(tracks$id, tracks$time),]

# adjust column types
tracks$year = as.factor(tracks$year)
# tracks$id = as.factor(tracks$id)
tracks$platform = as.factor(tracks$platform)
tracks$yday = as.numeric(tracks$yday)
tracks$lat = as.numeric(tracks$lat)
tracks$lon = as.numeric(tracks$lon)

# save
saveRDS(tracks, 'data/processed/tracks.rds')
