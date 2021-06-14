## proc_2021_tc_dash8_sightings ##
# Process sightings data from TC Dash-8 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2021_whalemapdata/TC_Dash8/'

# output file name
ofile = '2021_tc_dash8_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(stringr))

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '^(\\d{8})_Dash8_sightings.xls.$', full.names = T, recursive = T)

# only proceed if sightings files exist
if(length(flist)!=0){
  
  # list to hold loop output
  SIG = vector('list', length = length(flist))
  
  # read and format data ----------------------------------------------------
  
  # read files
  for(i in seq_along(flist)){
    
    # skip empty files
    if (file.size(flist[i]) == 0) next
    
    # read in data
    tmp = as.data.frame(read_excel(flist[i], sheet = 1, col_names = TRUE))
    
    if(!'Pos_lat' %in% names(tmp)){
      message('Skipping file without position data: ', flist[i])
      next
    }
    
    # select columns of interest
    tmp = data.frame(date = tmp$Date_UTC,
                     lat = tmp$Pos_lat,
                     lon = tmp$Pos_long,
                     time = tmp$Time_UTC,
                     species = tmp$Sp_code,
                     calves = tmp$calves,
                     number = tmp$Nb_total
    )
    
    # set date
    if(is.na(tmp$date[1])){
      # assign from filename
      tmp$date = as.Date(strsplit(basename(flist[i]), '_')[[1]][1], format = '%Y%m%d')
    } else {
      # assign from data
      tmp$date = as.Date(tmp$date[1]) # only use first date
    }
    
    # remove columns without data
    tmp = tmp[!is.na(tmp$species)&
                !is.na(tmp$lat)&
                !is.na(tmp$lon)&
                !is.na(tmp$time),]
    
    # skip if nothing seen
    if (nrow(tmp) == 0) next
    
    # fix time
    tmp$time = as.POSIXct(tmp$time, tz = 'UTC')
    tmp$time = as.POSIXct(paste0(tmp$date, ' ', hour(tmp$time), ':', minute(tmp$time), ':', second(tmp$time)), 
                          tz = 'UTC', usetz = T)
    
    # fix lat/lon
    tmp$lat = ddm2dd_col(tmp$lat)
    tmp$lon = -ddm2dd_col(tmp$lon)
    
    # add species identifiers
    tmp$species = toupper(tmp$species)
    tmp$species[tmp$species == 'EG'] = 'right'
    tmp$species[tmp$species == 'MN'] = 'humpback'
    tmp$species[tmp$species == 'BB'] = 'sei'
    tmp$species[tmp$species == 'BP'] = 'fin'
    tmp$species[tmp$species == 'FS'] = 'fin/sei'
    tmp$species[tmp$species == 'BA'] = 'minke'
    tmp$species[tmp$species == 'BM'] = 'blue'
    tmp$species[tmp$species == 'LWNR'] = 'unknown rorqual'
    tmp$species[tmp$species == 'UnWh'] = 'unknown large whale'
    tmp$species[tmp$species == 'UC'] = 'unknown cetacean'
    
    # add metadata
    tmp$yday = yday(tmp$date)
    tmp$year = year(tmp$date)
    tmp$score = 'sighted'
    tmp$platform = 'plane'
    tmp$name = 'tc_dash8'
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    tmp$source = 'WhaleMap'
    tmp$calves[which(is.na(tmp$calves))] = 0
    
    # add to list
    SIG[[i]] = tmp
    
    # catch null error
    if(is.null(SIG[[i]])){stop('Sightings in ', flist[i], ' not processed correctly!')}
    
  }
  
  # combine and save --------------------------------------------------------
  
  # combine all flights
  SIGS = bind_rows(SIG)
  
} else { # if no sightings files exist
  
  # make empty data frame
  SIGS = data.frame()
}

# config flight data
sig = config_observations(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))
