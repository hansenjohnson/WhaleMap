## proc_2020_dfo_coriolis_sightings ##
# process 2020 coriolis sightings

# input -------------------------------------------------------------------

# sightings data file
ifile = 'data/raw/2020_whalemapdata/DFO_Coriolis/2020_DFO_Cor_SightEffortEnviro.xlsx'

# output file name
ofile = 'data/interim/2020_dfo_coriolis_sightings.rds'

# setup -------------------------------------------------------------------

library(readxl)
library(lubridate)
source('R/functions.R')

# process -----------------------------------------------------------------

# read in data
tmp = read_excel(ifile) %>%
  transmute(
    time = as.POSIXct(`Date/Time (UTC)`, tz = 'UTC'),
    date = as.Date(time),
    lat = `Lat (DD)`,
    lon = `Long (DD)`,
    species = Species,
    score = ID_cert,
    number = Best,
    calves = Calves,
    year = year(date),
    yday = yday(date),
    platform = 'vessel',
    name = 'dfo_coriolis',
    id = paste(date, platform, name, sep = '_'),
    source = 'WhaleMap'
  )

# update score
tmp$score[tmp$score=='Definite'] = 'sighted'
tmp$score[tmp$score=='Possible'] = 'possibly sighted'
tmp$score[tmp$score=='Probable'] = 'possibly sighted'

# update species
tmp$species[tmp$species == 'Harbour porpoise'] = 'porpoise'
tmp$species[tmp$species == 'Humpback whale'] = 'humpback'
tmp$species[tmp$species == 'Sei whale'] = 'sei'
tmp$species[tmp$species == 'North Atlantic right whale'] = 'right'
tmp$species[tmp$species == 'Fin whale'] = 'fin'
tmp$species[tmp$species == 'Minke whale'] = 'minke'
tmp$species[tmp$species == 'Blue whale'] = 'blue'
tmp$species[tmp$species == 'Unknown whale'] = 'unknown whale'

# config data types
sig = config_observations(tmp)

# save
saveRDS(sig, ofile)