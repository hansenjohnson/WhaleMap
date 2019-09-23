## proc_live_viking ##
# process acoustic detections from DFO viking buoys

# input -------------------------------------------------------------------

# input files
det_ifile = 'data/raw/viking/live.json'
trk_ifile = 'data/raw/viking/buoys.csv'

# output files
det_ofile = 'data/interim/2019_dfo_viking_detections.rds'
trk_ofile = 'data/interim/2019_dfo_viking_tracks.rds'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(lubridate))

# helper functions
source('R/functions.R')

# tracks ------------------------------------------------------------------

# read in position data
pos = read.csv(trk_ifile, as.is = T)

# update buoy names and id
pos$name = paste0('dfo_viking_', pos$name)
pos$id = paste0(pos$start_date, '_buoy_', pos$name)
TRK = vector('list', length = nrow(pos))

for(ii in 1:nrow(pos)){
  
  # determine end date
  if(is.na(pos$end_date[ii])){
    end_date = Sys.Date()
  } else {
    end_date = as.Date(pos$end_date[ii])
  }
  
  # define data with initial columns
  tmp = data.frame(
    date = seq(as.Date(pos$start_date[ii]), end_date, 1),
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
tracks = suppressWarnings(bind_rows(TRK))

# format
tracks = config_tracks(tracks)

# save
saveRDS(tracks, file = trk_ofile)

# detections --------------------------------------------------------------

# read in detection data
tmp = suppressWarnings(as.character(readLines(det_ifile)))
tmp = gsub(x = tmp, pattern = "callback\\(", replacement = "")
tmp = substr(tmp, start = 1, stop = nchar(tmp)-1)

# extract data
jsn = jsonlite::fromJSON(tmp)

# select presence data
jsn = subset(jsn, presence == 1)

# format
df = data.frame(
  time = as.POSIXct(jsn$event$dateText, tz = 'UTC'),
  lat = jsn$event$location$latitude,
  lon = jsn$event$location$longitude,
  name = paste0('dfo_viking_', jsn$event$location$name__),
  platform = 'buoy',
  score = 'detected',
  species = 'right'
)

# add metadata
df$id = paste0('2019-06-01_',df$platform, '_', df$name)
df$date = as.Date(df$time)
df$yday = yday(df$time)
df$year = year(df$time)

# coerce to standard format
obs = config_observations(df)

# write data
saveRDS(object = obs, file = det_ofile)