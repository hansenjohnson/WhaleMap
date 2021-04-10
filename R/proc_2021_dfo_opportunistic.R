## proc_2021_dfo_opportunistic ##
# process 2021 dfo opportunistic right whales sightings

# input -------------------------------------------------------------------

# input file
ifile = 'data/raw/2021_whalemapdata/2021_General_Opportunistic_Sightings/2021-NARW-General_opportunistic-sightings.xlsx'

# directory for output
ofile = 'data/interim/2021_dfo_opportunistic_sightings.rds'

# column names (in order of sheet)
cnames = c('date', 'time', 'lat', 'lon', 'number', 'calves', 'platform', 'photos', 'verified', 'notes')

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(readxl))
source('R/functions.R')

# process data ------------------------------------------------------------

# read in spp and obs keys
sig = read_excel(ifile)
colnames(sig) = cnames

if(nrow(sig)>0){
  
  # wrangle time
  time = paste0(sig$date, ' ', sig$time)
  sig$time = as.POSIXct(time, format = '%m/%d/%Y %H:%M:%S', tz = 'UTC', usetz=TRUE)
  
  # wrangle date
  sig$date = as.Date(sig$date, format = '%m/%d/%Y')
  sig$yday = yday(sig$date)
  sig$year = year(sig$date)
  
  # wrangle text
  sig$verified = tolower(sig$verified)
  sig$photos = tolower(sig$photos)
  
  # sighting info
  sig$species = 'right'
  sig$score = 'possibly sighted'
  sig$score[sig$verified == 'yes'] = 'sighted'
  
  # remove columns
  sig$photos = NULL
  sig$notes = NULL
  sig$verified = NULL
  
  # convert number to numeric
  sig$number = as.character(sig$number)
  sig$number = gsub(pattern = "\\?", replacement = NA, x = sig$number)
  sig$number = as.numeric(sig$number)
  
  # convert calves to numeric
  sig$calves = as.character(sig$calves)
  sig$calves = gsub(pattern = "\\?", replacement = NA, x = sig$calves)
  sig$calves = as.numeric(sig$calves)
  
  # clean lat lons
  sig = clean_latlon(sig)
  
  # add metadata
  sig$name = sig$platform
  sig$platform = 'opportunistic'
  sig$id = paste0(sig$date, '_', sig$platform, '_', sig$name)
}

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, ofile)
