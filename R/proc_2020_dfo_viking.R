## proc_2020_dfo_viking ##
# get and process data from DFO viking buoys

# input -------------------------------------------------------------------

# buoy positions / names
pos_file = 'data/raw/2020_viking/buoy_positions.csv'

# raw file directory (store downloaded json)
raw_dir = 'data/raw/2020_viking/'

# output files
trk_file = 'data/interim/2020_dfo_viking_tracks.rds'
det_file = 'data/interim/2020_dfo_viking_detections.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
suppressPackageStartupMessages(library(jsonlite))

# tracks ------------------------------------------------------------------

# start and end date
start_date = '2020-05-01'
end_date = Sys.Date()

# read in buoy table
pos = read_csv(pos_file, col_types = cols())

# get status info
TRK = vector('list', length = length(pos$name))
for(ii in seq_along(pos$name)){
  
  # define buoy
  ibuoy = pos$name[ii]
  ilat = pos$lat[ii]
  ilon = pos$lon[ii]
  
  # define status URL
  status_url = paste0('https://harverstervikingbaleine.prod.ogsl.ca/api/buoy_status/', ibuoy ,'?date_range_min=', start_date, '&date_range_max=', end_date)
  
  # convert to table
  tmp = jsonlite::fromJSON(status_url)
  TRK[[ii]] = tibble(
    date = as.Date(names(tmp)),
    name = ibuoy,
    lat = ilat,
    lon = ilon,
    status = as.character(sapply(X = tmp, FUN = function(x)x[1]))  
  )
}

# flatten and remove offline instruments
trk = bind_rows(TRK) %>% filter(status == TRUE)

# add metadata
tracks = tibble(
  time = as.POSIXct(paste0(trk$date, 00:00:00), tz = 'UTC'),
  date = trk$date,
  yday = yday(date),
  year = year(date),
  lat = trk$lat,
  lon = trk$lon,
  name = paste0('dfo_viking_', trk$name),
  speed = NA,
  altitude = NA,
  platform = 'buoy',
  id = paste(start_date, platform, name, sep = '_')
)

# format
tracks = config_tracks(as.data.frame(tracks))

# save
saveRDS(object = tracks, file = trk_file)

# detections --------------------------------------------------------------

# define detection url
detection_url = paste0('https://www.ogsl.ca/beluga/biodiversity/occurrenceMeasurements/paginatedOccurrenceMeasurements?%24expand=event%2C+event%2Flocation%2C+event%2FdateFormat%2C+extradata%2C+establishmentMeans&%24filter=event%2FeventDateTime+ge+datetime%27',start_date,'T00%3A42%3A28.000Z%27+and+event%2FeventDateTime+le+datetime%27',end_date,'T23%3A40%3A38.000Z%27+and+event%2Fdataset%2Fcollection%2Fid+in+(29)&%24orderby=&%24skip=0&%24top=100&%24language=en')

# download file (using system call to wget)
tmp_file = paste0(raw_dir, 'detections.json')
system(paste0('wget -O "', tmp_file, '" "', detection_url,'" -q'))

# read in detection data
tmp = suppressWarnings(as.character(readLines(tmp_file)))
tmp = gsub(x = tmp, pattern = "callback\\(", replacement = "")
tmp = substr(tmp, start = 1, stop = nchar(tmp)-1)

# extract data
jsn = jsonlite::fromJSON(tmp)

det = tibble(
  time = as.POSIXct(jsn$event$dateText, tz = 'UTC'),
  date = as.Date(time),
  yday = yday(date),
  year = year(date),
  lat = jsn$event$location$latitude,
  lon = jsn$event$location$longitude,
  name = paste0('dfo_viking_', jsn$event$location$name__),
  species = 'right',
  score = 'detected',
  number = NA,
  calves = NA,
  platform = 'buoy',
  id = paste(start_date, platform, name, sep = '_')
)

# format
detections = config_observations(as.data.frame(det))

# save
saveRDS(object = detections, file = det_file)
