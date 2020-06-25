## proc_2020_niha_sightings ##
# process 2020 right whales sightings from Nick Hawkins

# input -------------------------------------------------------------------

# sightings data directory
data_dir = 'data/raw/2020_niha/'

# output file name
out_file = 'data/interim/2020_niha_sightings.rds'

# setup -------------------------------------------------------------------

library(readxl)
source('R/functions.R')

# process -----------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = 'datasheet*.*.xlsx$', full.names = T, recursive = T)

# list to hold loop output
SIG = vector('list', length = length(flist))
# read files
for(i in seq_along(flist)){

  # input file
  ifile = flist[i]
  
  if(ifile == "data/raw/2020_niha//2020-06-09/datasheet_2020-06-09-NIHA.xlsx"){
    message('Skipping file from June 09 until confirmation it is correct...')
    next
  }
  
  # extract date from file name
  fdate = as.Date(basename(ifile), format = 'datasheet_%Y-%m-%d-NIHA.xlsx')
  
  # read in spp and obs keys
  tmp = suppressMessages(as.data.frame(read_excel(ifile, skip = 3)))
  
  # extract required columns
  tmp = tmp[c(1,2,4,6,7,8)]
  
  # rename
  colnames(tmp) = c('time', 'lat', 'lon', 'number', 'calves','score')

  # update metadata
  tmp$lat = dms2dd_col(tmp$lat)
  tmp$lon = -dms2dd_col(tmp$lon)
  tmp$date = fdate
  tmp$time = with_tz(as.POSIXct(paste0(fdate, ' ', format(tmp$time, '%H:%M:%S')), tz = 'America/Halifax'), tzone = 'UTC')
  tmp$year = year(tmp$date)
  tmp$yday = yday(tmp$date)
  tmp$score[tmp$score=='definite visual'] = 'sighted'
  tmp$score[tmp$score=='possible visual'] = 'possibly sighted'
  tmp$species = 'right'
  tmp$calves = NA
  tmp$platform = 'vessel'
  tmp$name = 'calanus'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # add to list
  SIG[[i]] = tmp
}

# combine all
SIGS = as.data.frame(bind_rows(SIG))

# config data types
sig = config_observations(SIGS)

# save
saveRDS(sig, out_file)