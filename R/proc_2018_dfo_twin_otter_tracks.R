## proc_2018_dfo_twin_otter_tracks ##
# Process gps data from DFO Twin Otter survey plane
# Also run proc_2018-04-03_dfo_transit_tracks, and proc_2018-08-04_dfo_twin_otter_error.R

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/DFO_twin_otter/'

# output file name
ofile = '2018_dfo_twin_otter_tracks.rds'

# output directory
output_dir = 'data/interim/'

# list files to skip
fskip = c("data/raw/2018_whalemapdata/DFO_twin_otter//20180921/001231.gps",
          "data/raw/2018_whalemapdata/DFO_twin_otter//20180921/180921.gps")

# process one-off transit mission
source('R/proc_2018-04-03_dfo_transit_tracks.R')

# process missions with gps error
source('R/proc_2018_dfo_twin_otter_gps_error.R')

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)

# functions
source('R/functions.R')

# plot tracks?
plot_tracks = !on_server()

# list files to process
flist = list.files(data_dir, pattern = '.gps$', full.names = T, recursive = T)

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # skip empty files
  if (file.size(flist[i]) == 0 | grepl(pattern = 'error', x = flist[i])){
    message('Skipping empty or corrupted file ', flist[i])
    next
  }
  
  # # skip error flights
  # if (dirname(flist[i]) == 'data/raw/2018_whalemapdata/DFO_twin_otter//20180901'){
  #   message('Skipping empty or incomplete file ', flist[i])
  #   next
  # }
  
  # skip specific gps files
  if (flist[i] %in% fskip){
    message('Skipping file ', flist[i])
    next
  }
  
  # read in data (method below is slower but more robust to errors in gps file)
  textLines = readLines(flist[i])
  counts = count.fields(textConnection(textLines), sep=",")
  tmp = read.table(text=textLines[counts == 7], header=FALSE, sep=",")
  
  # select and rename important columns
  tmp = data.frame(tmp$V1, tmp$V3, tmp$V2, tmp$V4, tmp$V6)
  colnames(tmp) = c('time', 'lon', 'lat', 'speed', 'altitude')
  
  # remove bogus lat
  tmp[tmp$lat<30,] = NA
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
  
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
  tracks$name = 'dfo_twin_otter'
  tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
  
  # plot track
  if(plot_tracks){
    plot_save_track(tracks, flist[i])
  }
  
  # add to list
  TRK[[i]] = tracks
  
  # catch null error
  if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
# if(length(TRK)!=length(flist)){stop('Not all tracks were processed!')}

# combine all flights
TRACKS = do.call(rbind, TRK)
  
# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
