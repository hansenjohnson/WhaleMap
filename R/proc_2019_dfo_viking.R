## proc_2019_dfo_viking ##
# process acoustic detections from DFO viking buoys

# input -------------------------------------------------------------------

# input data
trk_ifile = 'data/raw/2019_whalemapdata/DFO_viking_buoys/positions.csv'
det_ifile = 'data/raw/2019_whalemapdata/DFO_viking_buoys/detections.csv'

# outfiles
trk_ofile = 'data/interim/2019_dfo_viking_tracks.rds'
det_ofile = 'data/interim/2019_dfo_viking_detections.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
suppressPackageStartupMessages(library(lubridate))

# process -----------------------------------------------------------------

# read in position data
pos = read.csv(trk_ifile)

# update buoy names and id
pos$name = paste0('VIKING-', pos$name)
pos$id = paste0(pos$date_deployed, '_buoy_', pos$name)

TRK = vector('list', length = nrow(pos))
for(ii in 1:nrow(pos)){
  
  # define data with initial columns
  tmp = 
    data.frame(
      date = seq(as.Date(pos$date_deployed[ii]), Sys.Date(), 1),
      time = NA,
      platform = 'buoy',
      lat = pos$lat[ii],
      lon = pos$lon[ii],
      name = pos$name[ii],
      year = 2019,
      id = pos$id[ii]
    )
  
  # add derived columns
  tmp$time = as.POSIXct(paste0(tmp$date, ' 12:00:00'))
  tmp$yday = yday(tmp$date)
  
  # store
  TRK[[ii]] = tmp
}

# combine
tracks = bind_rows(TRK)

# format
tracks = config_tracks(tracks)

# save
saveRDS(tracks, file = trk_ofile)

# read in detections
det = read.csv(file = det_ifile)

# update buoy names
det$name = paste0('VIKING-', det$name)

# initialize data
obs = data.frame(
  time = as.POSIXct(det$datetime, format = '%Y-%m-%d_%H%M%S'),
  platform = 'buoy',
  species = 'right',
  score = 'detected',
  number = NA,
  lat = NA,
  lon = NA,
  name = det$name,
  year = 2019
)

# add derived columns
obs$date = as.Date(obs$time)
obs$yday = yday(obs$time)

# match detections with positions
ind = match(obs$name, pos$name)

# add position and id data
obs$lat = pos$lat[ind]
obs$lon = pos$lon[ind]
obs$id = pos$id[ind]

# configure output data
obs = config_observations(obs)

# save data
saveRDS(obs, file = det_ofile)
