## proc_2021_tc_rpas_tracks ##
# Process gps data from TC RPAS survey

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2021_whalemapdata/TC_RPAS/'

# output file name
ofile = 'data/interim/2021_tc_rpas_tracks.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# tracks ------------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = '^(\\d{8}).kml$', full.names = T, recursive = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read files
for(ii in seq_along(flist)){
  
  # determine flight date from file name
  fdate = as.Date(x = dirname(flist[ii]), format = paste0(data_dir, '/%Y%m%d'))
  ftime = as.POSIXct(paste0(fdate, ' 12:00:00 UTC'), tz = 'UTC')
  
  # read in file
  tmp = suppressWarnings(rgdal::readOGR(dsn = flist[ii],verbose = F)) %>%
    coordinates() %>%
    as.data.frame()
  
  # format
  tmp = tmp %>% transmute(
    date = fdate,
    time = ftime+seq(1,nrow(tmp),1),
    lat = X2,
    lon = X1,
    yday = yday(date),
    year = year(date),
    platform = 'rpas',
    name = 'tc_rpas',
    id = paste(date, platform, name, sep = '_'),
    speed = NA,
    altitude = NA
  )
  
  # add to list
  TRK[[ii]] = subsample_gps(gps = tmp)
  
  # catch null error
  if(is.null(TRK[[ii]])){stop('Track in ', flist[ii], ' not processed correctly!')}
}

## combine and save

# catch errors
if(length(TRK)!=length(flist)){stop('Not all tracks were processed!')}

# combine all flights
TRACKS = bind_rows(TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, ofile)
