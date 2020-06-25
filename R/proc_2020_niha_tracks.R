## proc_2020_niha_tracks ##
# Process gps data from Hawkins surveys

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2020_niha/Tracks/'

# output file name
ofile = 'data/interim/2020_niha_tracks.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# read and format data ----------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = '.gpx', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read files
for(i in seq_along(flist)){
  
  # read in file
  tmp = read_GPX(flist[i])
  
  # dummy variable for speed
  tmp$speed = NA
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # add timestamp
  tmp$time = with_tz(as.POSIXct(tmp$time, tz = 'America/Halifax'), tzone = 'UTC')
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'vessel'
  tracks$name = 'calanus'
  tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
  
  # add to list
  TRK[[i]] = tracks
  
  # catch null error
  if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
  
}

# combine all flights
TRACKS = bind_rows(TRK)

# combine and save --------------------------------------------------------

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, ofile)
