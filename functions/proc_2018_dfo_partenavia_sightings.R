## proc_2018_dfo_partenavia_sightings ##
# Process sightings data from DFO partenavia

# user input --------------------------------------------------------------

# input file
data_dir = 'data/raw/2018_whalemapdata/DFO_partenavia/'

# output file name
ofile = '2018_dfo_partenavia_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
library(measurements, quietly = T, warn.conflicts = F)
library(readxl, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')

# list files to process
flist = list.files(data_dir, pattern = 'PartenaviaObs(\\d{8}).xlsx$', full.names = T, recursive = T)

# list to hold loop output
SIG = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in data from excel
  tmp = as.data.frame(read_xlsx(flist[i]))
  n = ncol(tmp)
  
  # fix time
  if('Hour' %in% colnames(tmp)){
    hrs = substr(as.character(tmp$Hour), start = 12, stop = 20)
    tmp$time = as.POSIXct(paste0(tmp$Date, ' ', hrs), format = '%m-%d-%Y %H:%M:%S', tz = 'UTC', usetz = TRUE)
  } else {
    tmp$time = NA
  }
  
  # add data
  tmp$date = as.Date(tmp$Date, format = '%m-%d-%Y')
  tmp$lat = as.numeric(tmp$Lat)
  tmp$lon = abs(as.numeric(tmp$Long))*-1
  tmp$number = as.numeric(tmp$Quant.)
  
  # add metadata
  tmp$yday = yday(tmp$date)
  tmp$year = year(tmp$date)
  tmp$score = 'sighted'
  tmp$platform = 'plane'
  tmp$name = 'dfo_partenavia'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # fix species
  tmp$species = NA
  tmp$Species = tolower(tmp$Species)
  tmp$species[tmp$Species == 'bb'] = 'sei'
  tmp$species[tmp$Species == 'bm'] = 'blue'
  tmp$species[tmp$Species == 'bp'] = 'fin'
  tmp$species[tmp$Species == 'eg'] = 'right'
  tmp$species[tmp$Species == 'mn'] = 'humpback'
  tmp$species[tmp$Species == 'fs'] = 'fin/sei'
  
  # remove original columns
  tmp = tmp[-c(1:n)]
  
  # remove NA sightings
  tmp = tmp[!is.na(tmp$species),]
  
  # add to list
  SIG[[i]] = tmp
  
  # catch null error
  if(is.null(SIG[[i]])){stop('Sightings in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
# if(length(SIG)!=length(flist)){stop('Not all sightings were processed!')}

# combine all flights
SIGS = do.call(rbind.data.frame, SIG)

# config flight data
sig = config_observations(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))