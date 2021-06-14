## proc_2021_dfo_opportunistic ##
# process 2021 dfo opportunistic right whales sightings

# input -------------------------------------------------------------------

# input file
dfo_ifile = 'data/raw/2021_whalemapdata/2021_General_Opportunistic_Sightings/2021-NARW-General_opportunistic-sightings.xlsx'
ccgs_ifile = 'data/raw/2021_whalemapdata/2021-CCGS_Opportunistic_Sightings/2021-NARW-CCGS_opportunistic-sightings.xlsx'

# directory for output
ofile = 'data/interim/2021_dfo_opportunistic_sightings.rds'

# column names (in order of sheet)
cnames = c('date', 'time', 'lat', 'lon', 'number', 'calves', 'platform', 'photos', 'verified', 'notes')

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(readxl))
source('R/functions.R')

# process data ------------------------------------------------------------

# read in spp and obs keys
sig_dfo = read_excel(dfo_ifile)
sig_ccgs = read_excel(ccgs_ifile)
sig = bind_rows(sig_dfo, sig_ccgs)
colnames(sig) = cnames

if(nrow(sig)>0){
  
  # wrangle time
  time = paste0(sig$date, ' ', format(sig$time, '%H:%M:%S'))
  sig$time = as.POSIXct(time, format = '%Y-%m-%d %H:%M:%S', tz = 'UTC', usetz=TRUE)
  
  # wrangle date
  sig$date = as.Date(sig$date)
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
  sig$id = paste0(sig$date, '_', sig$platform, '_dfo-report-', sig$name)
  sig$source = 'WhaleMap'
}

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, ofile)
