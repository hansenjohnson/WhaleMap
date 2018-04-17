## proc_2018_tc_dash8_sightings ##
# Process sightings data from TC Dash-8 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/TC_dash8/'

# output file name
ofile = '2018_tc_dash8_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
library(measurements, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')

# list files to process
flist = list.files(data_dir, pattern = 'Aerial_Survey_data_.*.csv$', full.names = T, recursive = T)

# list to hold loop output
SIG = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # skip empty files
  if (file.size(flist[i]) == 0) next
  
  # read in data
  tmp = read.csv(flist[i], stringsAsFactors = F)
  
  # select important columns
  tmp = tmp[,c(1,2,12,13,17,18)]
  
  # rename
  colnames(tmp) = c('date','time', 'species', 'number', 'lat', 'lon')
  
  # fix date
  tmp$date = as.Date(tmp$date[1], format = '%m/%d/%Y')
  
  # remove columns without species
  tmp = tmp[!tmp$species == '',]
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # add timestamp
  tmp$time = as.POSIXct(paste0(tmp$date, ' ', tmp$time), format = '%Y-%m-%d %H:%M:%S', tz="UTC", usetz=TRUE)
  
  # fix lat
  tmp$lat = gsub(pattern = 'N', replacement = '', tmp$lat)
  tmp$lat = round(as.numeric(measurements::conv_unit(tmp$lat, from = 'deg_dec_min', to = 'dec_deg')), 5)
  
  # fix lon
  tmp$lon = gsub(pattern = 'W', replacement = '', tmp$lon)
  tmp$lon = round(as.numeric(measurements::conv_unit(tmp$lon, from = 'deg_dec_min', to = 'dec_deg'))*-1, 5)
  
  # add species identifiers
  tmp$species[tmp$species == 'EG'] = 'right'
  tmp$species[tmp$species == 'MN'] = 'humpback'
  tmp$species[tmp$species == 'BB'] = 'sei'
  tmp$species[tmp$species == 'BP'] = 'fin'
  tmp$species[tmp$species == 'FS'] = 'fin/sei'
  tmp$species[tmp$species == 'BA'] = 'minke'
  tmp$species[tmp$species == 'BM'] = 'blue'
  tmp$species[tmp$species == 'LGWH'] = 'unknown whale'
  
  # add metadata
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$date)
  tmp$year = year(tmp$date)
  tmp$score = 'sighted'
  tmp$platform = 'plane'
  tmp$name = 'tc'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # add to list
  SIG[[i]] = tmp
  
  # catch null error
  if(is.null(SIG[[i]])){stop('Sightings in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
if(length(SIG)!=length(flist)){stop('Not all sightings were processed!')}

# combine all flights
SIGS = do.call(rbind, SIG)

# config flight data
sig = config_observations(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))
