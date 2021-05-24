## proc_2019_dfo_coriolis_sightings ##
# process 2019 coriolis sightings

# input -------------------------------------------------------------------

# sightings data file
ifile = 'data/raw/2019_whalemapdata/DFO_Coriolis/2019_DFO_Cor_SightEnviroEffortClean.xlsx'

# output file name
ofile = 'data/interim/2019_dfo_coriolis_sightings.rds'

# setup -------------------------------------------------------------------

library(readxl)
library(lubridate)
source('R/functions.R')

# process -----------------------------------------------------------------

# read in data
tmp = read_excel(ifile) %>%
  transmute(
    time = as.POSIXct(`DateTime (UTC)`, tz = 'UTC'),
    date = as.Date(time),
    lat = `LatDD`,
    lon = `LongDD`,
    species = SPECIES,
    score = SPP.Certainty,
    number = NUMB,
    calves = NA,
    year = year(date),
    yday = yday(date),
    platform = 'vessel',
    name = 'coriolis',
    id = paste(date, platform, name, sep = '_'),
    source = 'WhaleMap'
  )

# update score
tmp$score[tmp$score=='Definite'] = 'sighted'
tmp$score[tmp$score=='Possible'] = 'possibly sighted'
tmp$score[tmp$score=='Probable'] = 'possibly sighted'

# update species
species = tolower(tmp$species)
tmp$species = NA
tmp$species[species == 'humpback whale'] = 'humpback'
tmp$species[species == 'sei whale'] = 'sei'
tmp$species[species == 'right whale'] = 'right'
tmp$species[species == 'fin'] = 'fin'
tmp$species[species == 'fin whale whale'] = 'fin'
tmp$species[species == 'minke whale'] = 'minke'
tmp$species[species == 'blue whale'] = 'blue'

# config data types
sig = config_observations(tmp)

# save
saveRDS(sig, ofile)