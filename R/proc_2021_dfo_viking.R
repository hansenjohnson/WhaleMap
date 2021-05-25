## proc_2021_dfo_viking ##
# get and process data from DFO viking buoys

# input -------------------------------------------------------------------

# buoy positions / names
pos_file = 'data/raw/2021_viking/buoy_positions.csv'

# raw file directory (store downloaded json)
raw_dir = 'data/raw/2021_viking/'

# output files
trk_file = 'data/interim/2021_dfo_viking_tracks.rds'
det_file = 'data/interim/2021_dfo_viking_detections.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(httr))

# ignore SSL certificate errors
httr::set_config(httr::config(ssl_verifypeer = 0L)) 

# functions ---------------------------------------------------------------

get_jsn = function(jsn_url){
  
  # connect to url
  r = httr::RETRY("GET", jsn_url)
  
  # extract content
  txt = httr::content(r, "text", encoding = 'UTF-8')
  
  # convert to json
  jsn = jsonlite::fromJSON(txt)
  
  return(jsn)
}

# tracks ------------------------------------------------------------------

# # start and end date
# start_date = '2021-05-01'
# end_date = Sys.Date()+1
# 
# # read in buoy table
# pos = read_csv(pos_file, col_types = cols())
# 
# # get status info
# TRK = vector('list', length = length(pos$name))
# for(ii in seq_along(pos$name)){
#   
#   # define buoy
#   ibuoy = pos$name[ii]
#   ilat = pos$lat[ii]
#   ilon = pos$lon[ii]
#   
#   # define status URL
#   status_url = paste0('https://harverstervikingbaleine.prod.ogsl.ca/api/buoy_status/', ibuoy ,'?date_range_min=', start_date, '&date_range_max=', end_date)
#   
#   # get jsn data
#   tmp = get_jsn(status_url)
#   
#   # convert to table
#   TRK[[ii]] = tibble(
#     date = as.Date(names(tmp)),
#     name = ibuoy,
#     lat = ilat,
#     lon = ilon,
#     status = as.character(sapply(X = tmp, FUN = function(x)x[1]))  
#   )
# }
# 
# # flatten and remove offline instruments
# trk = bind_rows(TRK) %>% filter(status == TRUE)
# 
# # add metadata
# tracks = tibble(
#   time = as.POSIXct(paste0(trk$date, 00:00:00), tz = 'UTC'),
#   date = trk$date,
#   yday = yday(date),
#   year = year(date),
#   lat = trk$lat,
#   lon = trk$lon,
#   name = paste0('dfo_viking_', trk$name),
#   speed = NA,
#   altitude = NA,
#   platform = 'buoy',
#   id = paste(start_date, platform, name, sep = '_')
# )
# 
# # format
# tracks = config_tracks(as.data.frame(tracks))
# 
# # save
# saveRDS(object = tracks, file = trk_file)

# detections --------------------------------------------------------------

# define detection url
detection_url = paste0('https://www.ogsl.ca/beluga/biodiversity/occurrenceMeasurements/paginatedOccurrenceMeasurements?%24expand=event%2C+event%2Flocation%2C+event%2FdateFormat%2C+extradata%2C+establishmentMeans&%24filter=event%2FeventDateTime+ge+datetime%27',start_date,'T00%3A42%3A28.000Z%27+and+event%2FeventDateTime+le+datetime%27',end_date,'T23%3A40%3A38.000Z%27+and+event%2Fdataset%2Fcollection%2Fid+in+(29)&%24orderby=&%24language=en')

# get jsn data
jsn = get_jsn(detection_url)

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
