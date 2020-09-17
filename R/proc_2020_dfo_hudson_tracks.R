## proc_2020_dfo_hudson_tracks ##
# Process gps data from dfo coriolis surveys

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2020_whalemapdata/DFO_Hudson/'

# output file name
ofile = 'data/interim/2020_dfo_hudson_tracks.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# read and format data ----------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = 'voyage*.*.csv$', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read files
for(i in seq_along(flist)){
  
  # read csv 
  tmp = read_csv(flist[i], col_types = cols())  %>%
    transmute(
      date = Date,
      time = as.POSIXct(paste0(date, ' ', Time), tz = 'UTC'),
      lat = Latitude,
      lon = Longitude
    )
  
  # dummy variable for speed/altitude
  tmp$speed = NA
  tmp$altitude = 0
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'vessel'
  tracks$name = 'hudson'
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
