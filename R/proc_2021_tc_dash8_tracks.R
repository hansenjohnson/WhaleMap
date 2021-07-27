## proc_2021_tc_dash8_tracks ##
# Process gps data from TC Dash-8 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2021_whalemapdata/TC_Dash8/'

# output file name
ofile = '2021_tc_dash8_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressMessages(library(rgdal))
suppressMessages(library(lubridate))
suppressMessages(library(tools))

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '^(\\d{8})_Dash8_tracklog.*.csv$', full.names = T, recursive = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in file
  tmp = read.csv(flist[i], skip = 2)
  
  # determine flight date from file name
  fdate = as.Date(x = dirname(flist[i]), format = paste0(data_dir, '/%Y%m%d'))
  ftime = as.POSIXct(paste0(fdate, ' 12:00:00 UTC'), tz = 'UTC')
  
  # select and rename important columns
  tmp = tmp %>%
    transmute(
      date = fdate,
      time = ftime,
      lat = Latitude,
      lon = Longitude,
      speed = Speed,
      altitude = Altitude,
      yday = yday(date),
      year = year(date),
      platform = 'plane',
      name = 'tc_dash8',
      id = paste(date, platform, name, sep = '_')
    )
  
  # remove columns without timestamp
  tmp = tmp[!is.na(tmp$time),]
  
  # remove columns without lat lon
  tmp = tmp[!is.na(tmp$lat),]
  tmp = tmp[!is.na(tmp$lon),]
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add to list
  TRK[[i]] = tracks
  
  # catch null error
  if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
if(length(TRK)!=length(flist)){stop('Not all tracks were processed!')}

# combine all flights
TRACKS = bind_rows(TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
