## proc_2018_dfo_twin_otter_sightings ##
# Process sig data from DFO Twin Otter survey plane

# NOT DONE YET #

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/DFO_twin_otter/'

# output file name
ofile = '2018_dfo_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

# plot sightings?
# plot_sightings = T

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')
source('functions/subsample_gps.R')
# source('functions/plot_save_sightings.R')

# list files to process
flist = list.files(data_dir, pattern = '.sig', full.names = T, recursive = T)

# specify column names
# cnames = c('time', 'lon', 'lat', 'speed', 'altitude')

# list to hold loop output
SIG = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in data
  tmp = read.table(flist[i], sep = ',')
  
  # select and rename important columns
  tmp = data.frame(tmp$V1, tmp$V3, tmp$V2, tmp$V4, tmp$V6)
  colnames(tmp) = cnames
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
  
  # add metadata
  sig$date = as.Date(sig$time)
  sig$yday = yday(sig$date)
  sig$year = year(sig$date)
  sig$platform = 'plane'
  sig$name = 'dfo'
  sig$id = paste(sig$date, sig$platform, sig$name, sep = '_')
  
  # add to list
  SIG[[i]] = sig
  
  # catch null error
  if(is.null(SIG[[i]])){stop('Sightings in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
if(length(SIG)!=length(flist)){stop('Not all sightings were processed!')}

# combine all flights
SIGS = do.call(rbind, SIG)

# config flight data
sig = config_tracks(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))
