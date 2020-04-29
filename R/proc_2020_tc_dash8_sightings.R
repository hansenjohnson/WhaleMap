## proc_2020_tc_dash8_sightings ##
# Process sightings data from TC Dash-8 survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2020_whalemapdata/TC_Dash8/'

# output file name
ofile = '2020_tc_dash8_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(measurements))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(stringr))

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '(\\d{8})_Dash8_sightings.xls.$', full.names = T, recursive = T)

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
                     number = tmp$Nb_total
    )
    
    # fix date
    tmp$date = as.Date(tmp$date[1]) # only use first date
    
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
    
    # convert lat lon data type
    tmp$lat = as.character(tmp$lat)
    tmp$lon = as.character(tmp$lon)
    
    # add zeros to lat lons if necessary
    for(idf in 1:nrow(tmp)){
      if(str_count(tmp$lat[idf], ' ') == 0){
        tmp$lat[idf] = paste0(substr(tmp$lat[idf], 1, 2), ' ', substr(tmp$lat[idf], 3, 8))
      }
      if(str_count(tmp$lon[idf], ' ') == 0){
        tmp$lon[idf] = paste0(substr(tmp$lon[idf], 1, 2), ' ', substr(tmp$lon[idf], 3, 8))
      }
    }
    
    # remove any letter
    tmp$lat = gsub(pattern = 'N', replacement = '', x = tmp$lat)
    tmp$lon = gsub(pattern = 'W', replacement = '', x = tmp$lon)
    
    # remove any commas
    tmp$lat = gsub(pattern = ',', replacement = ' ', x = tmp$lat)
    tmp$lon = gsub(pattern = ',', replacement = ' ', x = tmp$lon)
    
    # remove minus sign
    tmp$lon = gsub(pattern = '-', replacement = '', x = tmp$lon)
    
    # determine lat lon format
    if(str_count(tmp$lat[1], ' ') == 2){
      ll_type = 'deg_min_sec'
    } else {
      ll_type = 'deg_dec_min'
    }
    
    # convert to decimal degrees (loop because vector behaviour is strange)
    for(ii in 1:nrow(tmp)){
      tmp$lat[ii] = round(as.numeric(measurements::conv_unit(tmp$lat[ii], from = ll_type, to = 'dec_deg')), 5)
      tmp$lon[ii] = round(as.numeric(measurements::conv_unit(tmp$lon[ii], from = ll_type, to = 'dec_deg'))*-1, 5)
    }
    
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
