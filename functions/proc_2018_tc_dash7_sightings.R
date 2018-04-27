## proc_2018_tc_dash7_sightings ##
# Process sightings data from TC Dash-7 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/TC_dash7/'

# output file name
ofile = '2018_tc_dash7_sightings.rds'

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
flist = list.files(data_dir, pattern = 'Validated entry.*.xlsx$', full.names = T, recursive = T)

# only proceed if sightings files exist
if(length(flist)!=0){
  
  # list to hold loop output
  SIG = list()
  
  # read and format data ----------------------------------------------------
  
  # read files
  for(i in seq_along(flist)){
    
    # skip empty files
    if (file.size(flist[i]) == 0) next
    
    # read in data
    tmp = as.data.frame(read_xlsx(flist[i], sheet = 1))
    
    # select columns of interest
    tmp = tmp[c(2,4,5,12,28,30)]
    
    # rename
    colnames(tmp) = c('date','lat', 'lon', 'time', 'species', 'number')
    
    # remove columns without species
    tmp = tmp[!is.na(tmp$species),]
    
    # fix date
    tmp$date = as.Date(tmp$date)
    
    # remove columns without timestamp
    tmp = tmp[which(!is.na(tmp$date)),]
    
    # remove columns without lat lon
    tmp = tmp[!is.na(tmp$lat),]
    tmp = tmp[!is.na(tmp$lon),]
    
    # fix time
    tmp$time = as.POSIXct(tmp$time)
    tmp$time = as.POSIXct(paste0(tmp$date, ' ', hour(tmp$time), ':', minute(tmp$time), ':', second(tmp$time)), 
                          tz = 'UTC', usetz = T)
    
    # fix lat
    tmp$lat = round(as.numeric(measurements::conv_unit(tmp$lat, from = 'deg_dec_min', to = 'dec_deg')), 5)
    
    # fix lon
    tmp$lon = round(as.numeric(measurements::conv_unit(tmp$lon, from = 'deg_dec_min', to = 'dec_deg'))*-1, 5)
    
    # add species identifiers
    tmp$species = toupper(tmp$species)
    tmp$species[tmp$species == 'EG'] = 'right'
    tmp$species[tmp$species == 'MN'] = 'humpback'
    tmp$species[tmp$species == 'BB'] = 'sei'
    tmp$species[tmp$species == 'BP'] = 'fin'
    tmp$species[tmp$species == 'FS'] = 'fin/sei'
    tmp$species[tmp$species == 'BA'] = 'minke'
    tmp$species[tmp$species == 'BM'] = 'blue'
    tmp$species[tmp$species == 'LGWH'] = 'unknown whale'
    
    # add metadata
    tmp$yday = yday(tmp$date)
    tmp$year = year(tmp$date)
    tmp$score = 'sighted'
    tmp$platform = 'plane'
    tmp$name = 'tc_dash7'
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
  
} else { # if no sightings files exist
  
  # make empty data frame
  SIGS = data.frame()
}

# config flight data
sig = config_observations(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))
