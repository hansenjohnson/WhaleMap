## proc_live_viking ##
# process acoustic detections from DFO viking buoys

# input -------------------------------------------------------------------

# data file
ifile = 'data/raw/viking/live.json'

# output file
ofile = 'data/interim/2019_dfo_viking_detections.rds'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(lubridate))

# helper functions
source('R/functions.R')

# process -----------------------------------------------------------------

# read in data
tmp = suppressWarnings(as.character(readLines(ifile)))
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
saveRDS(object = obs, file = ofile)