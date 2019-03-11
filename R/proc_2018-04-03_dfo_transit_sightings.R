## proc_2018-04-03_dfo_transit_sightings ##
# Process one-off transit flight from the DFO twin otter. Data provided by Jack Lawson on 2018-04-20

# user input --------------------------------------------------------------

# sightings file
sfile = 'data/raw/2018_whalemapdata/DFO_twin_otter/20180403_transit/April Deployment Flight Sightings.xls'

# output file names
sofile = '2018-04-03_dfo_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)
library(readxl, quietly = T, warn.conflicts = F)

# functions
source('R/functions.R')

# process sightings -------------------------------------------------------

# read in data from excel
obs = as.data.frame(read_xls(sfile))

# add data
obs$date = as.Date(paste0(obs$Year, '-', obs$Month, '-', obs$Day))
obs$time = NA
obs$lat = obs$Latitude
obs$lon = obs$Longitude
obs$number = obs$Number
obs$yday = yday(obs$date)
obs$year = year(obs$date)
obs$score = 'sighted'
obs$platform = 'plane'
obs$name = 'dfo'
obs$id = paste(obs$date, obs$platform, obs$name, sep = '_')

# fix species
obs$species = NA
obs$species[obs$Species == 'Large Whale'] = 'unknown whale'
obs$species[obs$Species == 'White-beaked Dolphin'] = 'white-beaked dolphin'
obs$species[obs$Species == 'Blue Whale'] = 'blue'
obs$species[obs$Species == 'Fin Whale' | obs$Species == '1 Fin Whale'] = 'fin'

# remove unused columns
obs = obs[-c(1:7)]

# config sightings data
obs = config_observations(obs)

# save
saveRDS(obs, paste0(output_dir, sofile))
