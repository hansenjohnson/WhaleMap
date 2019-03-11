## proc_2017_noaa_twin_otter_sightings ##
# Process sightings data from NOAA Twin Otter survey plane

# user input --------------------------------------------------------------

# data directory
ifile = 'data/raw/2017_noaa_twin_otter/canada2017_ap.csv'

# output file name
ofile = '2017_noaa_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')

# read and format data ----------------------------------------------------

# read in data
tmp = read.csv(ifile, header = T, stringsAsFactors = F)
colnames(tmp) = c('time', 'lat', 'lon', 'number', 'comments')

# remove columns without timestamp
tmp = tmp[which(!is.na(tmp$time)),]

# remove columns with dead whales
tmp = tmp[!grepl(pattern = '#', x = tmp$comments),]
tmp$comments = NULL

# add timestamp
tmp$time = as.POSIXct(tmp$time, tz="UTC", usetz=TRUE)

# fix numbers
tmp$number[tmp$number == '.'] = NA
tmp$number = as.numeric(tmp$number)

# add metadata
tmp$species = 'right'
tmp$date = as.Date(tmp$time)
tmp$yday = yday(tmp$date)
tmp$year = year(tmp$date)
tmp$score = 'sighted'
tmp$platform = 'plane'
tmp$name = 'noaa_twin_otter'
tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')

# config flight data
sig = config_observations(tmp)

# save
saveRDS(sig, paste0(output_dir, ofile))
