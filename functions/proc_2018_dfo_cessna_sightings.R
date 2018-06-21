## proc_2018_dfo_cessna_sightings ##
# Process sightings data from DFO cessna

# user input --------------------------------------------------------------

# input file
data_dir = 'data/raw/2018_whalemapdata/DFO_cessna/'

# output file name
ofile = '2018_dfo_cessna_sightings.rds'

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
flist = list.files(data_dir, pattern = '^(\\d{8}).xlsx$', full.names = T, recursive = T)

# list to hold loop output
SIG = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in data from excel
  tmp = as.data.frame(read_xlsx(flist[i]))
  
  tmp$time_UTC
  
  # fix date/time
  tmp$date = as.Date(tmp$Date_UTC, format = '%Y-%m-%d UTC')
  tmp$time = as.POSIXct(paste0(tmp$date, ' ', substr(tmp$time_UTC, start = 12, stop = 20)), tz = 'UTC')
  
  # add data
  tmp$lat = as.numeric(tmp$lat)
  tmp$lon = abs(as.numeric(tmp$long))*-1
  tmp$number = as.numeric(tmp$nb_tot)
  
  # add metadata
  tmp$yday = yday(tmp$date)
  tmp$year = year(tmp$date)
  tmp$score = 'sighted'
  tmp$platform = 'plane'
  tmp$name = 'dfo_cessna'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # fix species
  tmp$species = NA
  tmp$sp_code = toupper(tmp$sp_code)
  tmp$species[tmp$sp_code == 'BB'] = 'sei'
  tmp$species[tmp$sp_code == 'BM'] = 'blue'
  tmp$species[tmp$sp_code == 'BP'] = 'fin'
  tmp$species[tmp$sp_code == 'EG'] = 'right'
  tmp$species[tmp$sp_code == 'MN'] = 'humpback'
  tmp$species[tmp$sp_code == 'FS'] = 'fin/sei'
  
  # select columns of interest
  tmp = tmp[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]
  
  # remove NA sightings
  tmp = tmp[!is.na(tmp$species),]
  
  # add to list
  SIG[[i]] = tmp
  
}

# combine and save --------------------------------------------------------

# combine all flights
sig = do.call(rbind.data.frame, SIG)

# config flight data
sig = config_observations(sig)

# save
saveRDS(sig, paste0(output_dir, ofile))