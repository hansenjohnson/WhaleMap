## proc_2018_dfo_partenavia_cessna_sightings ##
# Process sightings data from DFO partenavia cessna

# user input --------------------------------------------------------------

# input file
ifile = 'data/raw/2018_whalemapdata/DFO_partenavia_cessna/PartenaviaDailyObs.xlsx'

# output file name
ofile = '2018_dfo_partenavia_cessna_sightings.rds'

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

# read in data from excel
obs = as.data.frame(read_xlsx(ifile))

# add data
obs$date = as.Date(obs$Date, format = '%m-%d-%Y')
obs$time = NA
obs$lat = obs$Lat
obs$lon = obs$Long
obs$number = obs$Quant.
obs$yday = yday(obs$date)
obs$year = year(obs$date)
obs$score = 'sighted'
obs$platform = 'plane'
obs$name = 'dfo_partenavia_cessna'
obs$id = paste(obs$date, obs$platform, obs$name, sep = '_')

# fix species
obs$species = NA
obs$Species = tolower(obs$Species)
obs$species[obs$Species == 'bb'] = 'sei'
obs$species[obs$Species == 'bm'] = 'blue'
obs$species[obs$Species == 'bp'] = 'fin'
obs$species[obs$Species == 'eg'] = 'right'
obs$species[obs$Species == 'mn'] = 'humpback'
obs$species[obs$Species == 'fs'] = 'fin/sei'

# remove unused columns
obs = obs[-c(1:9)]

# remove NA sightings
obs = obs[!is.na(obs$species),]

# config sightings data
obs = config_observations(obs)

# save
saveRDS(obs, paste0(output_dir, ofile))
