## proc_2018_jasco_detections ##
# Process detection data from JASCO glider(s)

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/jasco/'

# output file name
ofile = '2018_jasco_detections.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
library(tools, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')

# list files to process
flist = list.files(data_dir, pattern = 'detections.csv$', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
DET = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # read in file
  tmp = read.csv(flist[i])
  
  # convert column names
  colnames(tmp) = c('time', 'lat', 'lon', 'species', 'score')
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # convert timestamp
  tmp$time = as.POSIXct(as.character(tmp$time), format = '%Y%m%dT%H%M%S', tz = 'UTC')
  
  # provide glider name (isolate from dir name eventually)
  gname = 'test'
  
  # add metadata
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$date)
  tmp$year = year(tmp$date)
  tmp$platform = 'slocum'
  tmp$number = NA
  tmp$name = paste0('jasco_', gname)
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # convert species codes
  tmp$species = tolower(as.character(tmp$species))
  tmp$species[tmp$species == 'right whale'] = 'right'
  tmp$species[tmp$species == 'humpback whale'] = 'humpback'
  tmp$species[tmp$species == 'sei whale'] = 'sei'
  tmp$species[tmp$species == 'fin whale'] = 'fin'
  tmp$species[tmp$species == 'minke whale'] = 'minke'
  tmp$species[tmp$species == 'blue whale'] = 'blue'
  
  # convert scores
  tmp$score = as.character(tmp$score)
  tmp$score[tmp$score == 'definite'] = 'detected'
  tmp$score[tmp$score == 'possible'] = 'possibly detected'
  
  # add to list
  DET[[i]] = tmp
  
  # catch null error
  if(is.null(DET[[i]])){stop('Detections in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# combine all flights
DETECTIONS = do.call(rbind, DET)

# config flight data
detections = config_observations(DETECTIONS)

# save
saveRDS(detections, paste0(output_dir, ofile))
