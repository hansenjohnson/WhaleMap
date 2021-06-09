## proc_2019_dfo_coriolis_tracks ##
# Process gps data from dfo coriolis surveys

# user input --------------------------------------------------------------

# data directory
ifile = 'data/raw/2019_whalemapdata/DFO_Coriolis/2019_DFO_Cor_SightEnviroEffortClean.xlsx'

# output file name
ofile = 'data/interim/2019_dfo_coriolis_tracks.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')
library(readxl)

# read and format data ----------------------------------------------------

# read in data
tmp = read_excel(ifile, sheet = 2) %>%
  transmute(
    time = as.POSIXct(`DateTimeUTC`, format = '%d-%m-%Y %H:%M', tz = 'UTC'),
    date = as.Date(time),
    lat = `LatDD`,
    lon = `LongDD`,
    speed = NA,
    altitude = NA,
    year = year(date),
    yday = yday(date),
    platform = 'vessel',
    name = 'coriolis',
    id = paste(date, platform, name, sep = '_'),
    source = 'WhaleMap'
  )

# simplify tracks for each day
dates = unique(tmp$date)
TRK = vector('list', length = length(dates))
for(ii in seq_along(dates)){
  idate = dates[ii]
  itrk = tmp %>% filter(date == idate)
  TRK[[ii]] = subsample_gps(gps = itrk)
}

# combine all
TRACKS = bind_rows(TRK)

# config data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, ofile)
