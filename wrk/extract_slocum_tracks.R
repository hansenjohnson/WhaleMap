# extract glider tracks for Del's analysis
 
# track data --------------------------------------------------------------

# read in data
tracks = readRDS('data/processed/tracks.rds')

# subset in time
tracks = subset(tracks, year %in% c(2015,2016,2017))

# subset in space
# tracks = tracks[tracks$lon <= -57 & tracks$lon >= -66,]
# tracks = tracks[tracks$lat <= 51.5 & tracks$lat >= 45.5,]

# subset by platform
tracks = subset(tracks, platform == 'slocum')
tracks = subset(tracks, !id %in% c("2017-02-28_slocum_we03", "2015-04-11_slocum_we03", 
                                   "2016-09-23_slocum_we03", "2016-04-13_slocum_we03", 
                                   "2016-03-30_slocum_we03", "2016-07-24_slocum_otn201"))

# write to files
saveRDS(tracks, file = 'data/extracted/slocum_tracks.rds')

# check -------------------------------------------------------------------

plot(tracks$lon, tracks$lat, col = 'darkslategray', type = 'l')