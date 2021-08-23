## proc_2021_mics_tracks ##
# Process track data from MICS survey vessels

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2021_mics/Effort/'

# output file name
ofile = 'data/interim/2021_mics_tracks.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '.gpx', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  if(file.size(flist[i])<51200){
    message('Skipping small file: ', flist[i])
    next
  }
  
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
  
  # isolate vessel name
  vname = strsplit(basename(flist[i]), split = '-')[[1]][4]
  vname = tolower(gsub(x = vname, pattern = '.gpx', replacement = ''))
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'vessel'
  tracks$name = paste0('mics_', vname)
  tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
  
  # add to list
  TRK[[i]] = tracks
  
  # catch null error
  if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# combine all flights
TRACKS = bind_rows(TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, ofile)
