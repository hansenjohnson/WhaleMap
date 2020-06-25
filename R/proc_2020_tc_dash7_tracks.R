## proc_2020_tc_dash7_tracks ##
# Process gps data from TC Dash-7 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2020_whalemapdata/TC_Dash7/'

# output file name
ofile = 'data/interim/2020_tc_dash7_tracks.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '(\\d{8})_Dash7_tracklog.*.csv$', full.names = T, recursive = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in file
  tmp = read.csv(flist[i], skip = 2)
  
  # select and rename important columns
  tmp = data.frame(tmp$Timestamp, tmp$Longitude, tmp$Latitude, tmp$Speed, tmp$Altitude)
  colnames(tmp) = c('time', 'lon', 'lat', 'speed', 'altitude')
  
  # Correct for variable precision (or errors) in gps
  f = roundTen(tmp$time)/10^9
  tmp$time = tmp$time/f
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, origin = '1970-01-01', tz = 'UTC', usetz=TRUE)
  
  # remove columns without timestamp
  tmp = tmp[!is.na(tmp$time),]
  
  # remove columns without lat lon
  tmp = tmp[!is.na(tmp$lat),]
  tmp = tmp[!is.na(tmp$lon),]
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'plane'
  tracks$name = 'tc_dash7'
  tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
  
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
saveRDS(tracks,ofile)
