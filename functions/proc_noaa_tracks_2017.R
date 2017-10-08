# process and save noaa plane tracklines from 2017

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2017_noaa_plane_tracks/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate)
source('functions/config_data.R')

# find all data files
noaa_track_list = list.files(data_dir, pattern = '.gps', full.names = T)

# extract data
TRACKS = list()
for(i in seq_along(noaa_track_list)){
  TRACKS[[i]] = read.table(noaa_track_list[i], sep = ',')
}

# catch error
if(length(TRACKS)!=length(noaa_track_list)){stop('Not all tracks were processed!')}

# flatten tracks
tracks = do.call(rbind, TRACKS)
tracks = tracks[,-c(4:7)]

# rename
colnames(tracks) = c('time', 'lat', 'lon')

# wrangle time
tracks$time = as.POSIXct(tracks$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
tracks$date = as.Date(tracks$time)
tracks$yday = yday(tracks$time)
tracks$year = year(tracks$time)

# add deployment metadata
tracks$platform = 'plane'
tracks$name = 'noaa'
tracks$id = paste0(tracks$date, '_plane_noaa')

# subsample
norig = nrow(tracks)
npoints = norig/20 # initially plotted every 10 points, or every 20s. Trying only every 20 pts now...
nsub = round(norig/npoints,0)
tracks = tracks[seq(1, nrow(tracks), nsub),] # subset to plot every other data point

# configure column types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, '2017_noaa_tracks.rds'))
