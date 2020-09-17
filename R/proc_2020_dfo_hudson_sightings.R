## proc_2020_dfo_hudson_sightings ##
# process 2020 hudson sightings

# input -------------------------------------------------------------------

# sightings data directory
data_dir = 'data/raw/2020_whalemapdata/DFO_Hudson/'

# output file name
out_file = 'data/interim/2020_dfo_hudson_sightings.rds'

# setup -------------------------------------------------------------------

library(readxl)
source('R/functions.R')

# process -----------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = 'formdat*.*.xlsx$', full.names = T, recursive = T)

# list to hold loop output
SIG = vector('list', length = length(flist))
# read files
for(i in seq_along(flist)){
  
  # read in data
  tmp = read_excel(flist[i],sheet = "Sighting") %>%
    transmute(
      time = as.POSIXct(`DateT`, tz = 'UTC'),
      pos = Start_pos,
      species = Species,
      score = ID_cert,
      number = Best
    )
  
  # extract date from filename
  dt = as.Date(basename(flist[i]), format = 'formdat%Y%m%d-WhaleMap.xlsx')
  
  # extract time from file
  h_m_s = sapply(strsplit(as.character(tmp$time), ' '), FUN = function(x){x[2]})
  
  # fix time
  tmp$time = as.POSIXct(paste0(dt,' ', h_m_s), tz = 'UTC')
  
  # add date
  tmp$date = lubridate::date(tmp$time)
  
  # extract lat / lon
  lat = lapply(strsplit(tmp$pos, split = ' '),FUN = function(x){x[[1]]})
  lon = lapply(strsplit(tmp$pos, split = ' '),FUN = function(x){x[[2]]})
  
  # fix lat
  lat = gsub(lat, pattern = 'd', replacement = ' ')
  lat = gsub(lat, pattern = 'N', replacement = '')
  tmp$lat = ddm2dd_col(lat)
  
  # fix lon
  lon = gsub(lon, pattern = 'd', replacement = ' ')
  lon = gsub(lon, pattern = 'W', replacement = '')
  tmp$lon = -ddm2dd_col(lon)
  
  # remove column
  tmp$pos = NULL
  
  # update metadata
  tmp$year = year(tmp$date)
  tmp$yday = yday(tmp$date)
  tmp$platform = 'vessel'
  tmp$name = 'hudson'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # update score
  tmp$score[tmp$score=='Definite'] = 'sighted'
  tmp$score[tmp$score=='Possible'] = 'possibly sighted'
  tmp$score[tmp$score=='Probable'] = 'possibly sighted'
  
  # update species
  tmp$calves = NA
  tmp$species[tmp$species == 'Harbour porpoise'] = 'porpoise'
  tmp$species[tmp$species == 'Humpback whale'] = 'humpback'
  tmp$species[tmp$species == 'Sei whale'] = 'sei'
  tmp$species[tmp$species == 'North Atlantic right whale'] = 'right'
  tmp$species[tmp$species == 'Fin whale'] = 'fin'
  tmp$species[tmp$species == 'Minke whale'] = 'minke'
  tmp$species[tmp$species == 'Blue whale'] = 'blue'
  tmp$species[tmp$species == 'Unknown whale'] = 'unknown whale'
  
  # add to list
  SIG[[i]] = tmp
}

# combine all
SIGS = as.data.frame(bind_rows(SIG))

# config data types
sig = config_observations(SIGS)

# save
saveRDS(sig, out_file)