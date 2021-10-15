## proc_2021_dfo_hudson ##
# Process gps and sightings data from dfo hudson surveys

# input -------------------------------------------------------------------

# data directory
effort_dir = 'data/raw/2021_whalemapdata/DFO_CCGHudson/vessel_tracks/'
obs_file = 'data/raw/2021_whalemapdata/DFO_CCGHudson/2021_DFO_CCGHudson_Sightings.xlsx'

# output file names
efile = 'data/interim/2021_dfo_hudson_tracks.rds'
ofile = 'data/interim/2021_dfo_hudson_sightings.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')
library(readxl)

# effort ------------------------------------------------------------------

# list files to process
flist = list.files(effort_dir, pattern = '^(\\d{8}).*.csv$', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read files
for(ii in seq_along(flist)){
  
  # read csv 
  tmp = read_csv(flist[ii], col_types = cols())  %>%
    transmute(
      date = Date,
      time = as.POSIXct(paste0(date, ' ', Time), tz = 'UTC'),
      lat = Latitude,
      lon = Longitude
    )
  
  # dummy variable for speed/altitude
  tmp$speed = NA
  tmp$altitude = NA
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'vessel'
  tracks$name = 'dfo_hudson'
  tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
  
  # add to list
  TRK[[ii]] = tracks
  
  # catch null error
  if(is.null(TRK[[ii]])){stop('Track in ', flist[i], ' not processed correctly!')}
  
}

# combine all tracks
TRACKS = bind_rows(TRK)

# observations ------------------------------------------------------------

# column names (in order of sheet)
cnames = c('platform', 'date','time', 'lat', 'lon', 'species','sp_name', 'number', 'calves', 'photos', 'verified', 'notes')
ctypes = c('text', 'date', 'date', 'numeric', 'numeric', 'text', 'text', 'numeric', 'numeric', 'text', 'text', 'text')

# read in spp and obs keys
sig = read_excel(obs_file)


if(nrow(sig)>0){
  
  # wrangle time
  sig$date = as.Date(sig$`Date (YYYY/MM/DD)`, format = '%Y/%m/%d')
  time = paste0(sig$date, ' ', format(sig$`Time (UTC)`, '%H:%M:%S'))
  sig$time = as.POSIXct(time, format = '%Y-%m-%d %H:%M:%S', tz = 'UTC', usetz=TRUE)
  
  # wrangle date
  sig$date = as.Date(sig$date)
  sig$yday = yday(sig$date)
  sig$year = year(sig$date)
  
  # wrangle text
  sig$verified = tolower(sig$`Verified? (Yes/No)`)
  sig$photos = tolower(sig$`Photos?`)
  
  # sighting info
  sig$species = NA
  sig$species[sig$Sp_Code == 'MN'] = 'humpback'
  sig$species[sig$Sp_Code == 'BM'] = 'blue'
  sig$species[sig$Sp_Code == 'EG'] = 'right'
  sig$species[sig$Sp_Code == 'BP'] = 'fin'
  sig$species[sig$Sp_Code == 'BB'] = 'sei'
  sig$score = 'possibly sighted'
  sig$score[sig$verified == 'yes'] = 'sighted'
  
  # remove columns
  sig$photos = NULL
  sig$notes = NULL
  sig$verified = NULL
  
  # convert number to numeric
  sig$number = as.numeric(sig$`Number in group`)
  
  # convert calves to numeric
  sig$calves = as.numeric(sig$Calves)
  
  # clean lat lons
  sig$lat = sig$Pos_lat
  sig$lon = sig$Pos_long
  sig = clean_latlon(sig)
  
  # add metadata
  sig$name = 'dfo_hudson'
  sig$platform = 'vessel'
  sig$id = paste0(sig$date, '_', sig$platform, '_', sig$name)
  sig$source = 'WhaleMap'
}

# combine and save --------------------------------------------------------

# config effort data
tracks = config_tracks(TRACKS)

# config observation data
sig = config_observations(sig)

# save
saveRDS(tracks, efile)
saveRDS(sig, ofile)
