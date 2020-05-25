## proc_2020_dfo_twin_otter_tracks ##
# Process gps data from DFO twin otter survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2020_whalemapdata/DFO_twin_otter/'

# output file name
ofile = '2020_dfo_twin_otter_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '.gpx', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read and format data ----------------------------------------------------

if(length(flist!=0)){
  
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
    tracks$platform = 'plane'
    tracks$name = 'dfo_twin_otter'
    tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
    
    # add to list
    TRK[[i]] = tracks
    
    # catch null error
    if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
    
  }
  
  # combine all flights
  TRACKS = bind_rows(TRK)
  
} else {
  
  # assign empty data frame
  TRACKS = data.frame()
}

# combine and save --------------------------------------------------------

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
