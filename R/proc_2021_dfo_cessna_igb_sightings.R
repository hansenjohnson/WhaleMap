## proc_2021_dfo_cessna_yob_sightings ##
# Process sightings data from DFO cessna

# user input --------------------------------------------------------------

# input file
data_dir = 'data/raw/2021_whalemapdata/DFO_Cessna_IGB/'

# output file name
ofile = '2021_dfo_cessna_igb_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(measurements))
suppressPackageStartupMessages(library(readxl))

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '^(\\d{8}).xlsx$', full.names = T, recursive = T)

# list to hold loop output
SIG = list()

# read and format data ----------------------------------------------------

if(length(flist!=0)){
  
  # read files
  for(i in seq_along(flist)){
    
    # read in data from excel
    tmp = as.data.frame(read_xlsx(flist[i]))
    
    # find date column
    date_ind = grep(pattern = 'date_UTC', x = colnames(tmp), ignore.case = TRUE)
    
    # fix date/time
    tmp$date = as.Date(tmp[,date_ind], format = '%Y-%m-%d UTC')
    tmp$time = as.POSIXct(paste0(tmp$date, ' ', substr(tmp$time_UTC, start = 12, stop = 20)), tz = 'UTC')
    
    # add data
    tmp$lat = as.numeric(tmp$lat)
    tmp$lon = abs(as.numeric(tmp$long))*-1
    tmp$number = as.numeric(tmp$nb_tot)
    
    # add calves if column exists
    if("Mother_Calf_Pair" %in% colnames(tmp)){
      tmp$calves = as.numeric(tmp$Mother_Calf_Pair)
    } else {
      tmp$calves = NA
    }
    
    # add metadata
    tmp$yday = yday(tmp$date)
    tmp$year = year(tmp$date)
    tmp$score = 'sighted'
    tmp$platform = 'plane'
    tmp$name = 'dfo_cessna_igb'
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
    tmp = tmp[,c('time','lat','lon','date', 'yday','species','score','number','calves', 'year','platform','name','id')]
    
    # remove NA sightings
    tmp = tmp[!is.na(tmp$species),]
    
    # add to list
    SIG[[i]] = tmp
    
  }
  
  # combine all flights
  sig = bind_rows(SIG)
  
} else {
  
  # assign empty data frame
  sig = data.frame()
}

# combine and save --------------------------------------------------------

# config flight data
sig = config_observations(sig)

# save
saveRDS(sig, paste0(output_dir, ofile))