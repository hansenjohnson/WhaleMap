## noaa_twin_otter ##
# Process gps data from NOAA Twin Otter survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/noaa_twin_otter_tracks/'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate)
library(rgdal)

# functions
# source('functions/config_data.R')
source('functions/subsample_gps.R')

# list files to process
flist = list.files(data_dir, pattern = '.gps', full.names = T)

# specify column names
cnames = c('time', 'lon', 'lat', 'speed', 'altitude')

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in data
  tmp = read.table(flist[i], sep = ',')
  
  # select and rename important columns
  tmp = data.frame(tmp$V1, tmp$V3, tmp$V2, tmp$V4, tmp$V6)
  colnames(tmp) = cnames
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'plane'
  tracks$name = 'noaa'
  tracks$id = paste0(tracks$date, '_plane_noaa')
  
  # add to list
  TRK[[i]] = tracks
  
}

# combine and save --------------------------------------------------------

# catch errors
if(length(TRK)!=length(flist)){stop('Not all tracks were processed!')}

# combine all flights
TRACKS = do.call(rbind, TRK)

# save
saveRDS(tracks, paste0(output_dir, 'noaa_twin_otter_tracks.rds'))
