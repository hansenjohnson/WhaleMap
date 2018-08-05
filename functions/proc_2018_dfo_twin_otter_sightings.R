## proc_2018_dfo_twin_otter_sightings ##
# Process sightings data from DFO Twin Otter survey plane
# Also run proc_2018-04-03_dfo_transit_sightings

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2018_whalemapdata/DFO_twin_otter/'

# output file name
ofile = '2018_dfo_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

# process one-off transit mission
source('functions/proc_2018-04-03_dfo_transit_sightings.R')

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')

# list files to process
flist = list.files(data_dir, pattern = '.sig$', full.names = T, recursive = T, ignore.case = T)

# list to hold loop output
SIG = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # skip empty files
  if (file.size(flist[i]) == 0) next
  
  # read in data (method below is slower but more robust to errors in gps file)
  textLines = readLines(flist[i])
  counts = count.fields(textConnection(textLines), sep=",")
  tmp = read.table(text=textLines[counts == 21 & !is.na(counts)], header=FALSE, sep=",")
  
  # # read in data
  # tmp = read.table(flist[i], sep = ',')
  
  # assign column names
  colnames(tmp) = c('transect', 'unk1', 'unk2', 'time', 'observer', 'declination', 'species', 'number', 'unk4', 'bearing', 'unk5', 'unk6', 'comments', 'side', 'lat', 'lon', 'audio', 'unk7', 'photo', 'unk8', 'unk9')
  
  # remove columns without timestamp
  tmp = tmp[which(!is.na(tmp$time)),]
  
  # add timestamp
  tmp$time = as.POSIXct(tmp$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)
  
  # fix blank species rows
  tmp$species = as.character(tmp$species)
  tmp$species[tmp$species==""] = NA
  
  # remove columns without species
  tmp = tmp[which(!is.na(tmp$species)),]
  
  # skip to next if no sightings
  if (nrow(tmp) == 0) next
  
  # add species identifiers
  tmp$species = toupper(tmp$species)
  tmp$species[tmp$species == 'EG'] = 'right'
  tmp$species[tmp$species == 'MN'] = 'humpback'
  tmp$species[tmp$species == 'BB'] = 'sei'
  tmp$species[tmp$species == 'BP'] = 'fin'
  tmp$species[tmp$species == 'FS'] = 'fin/sei'
  tmp$species[tmp$species == 'BA'] = 'minke'
  tmp$species[tmp$species == 'BM'] = 'blue'
  tmp$species[tmp$species == 'UW'|tmp$species == 'LGWH'] = 'unknown whale'
  
  # remove duplicate sightings
  tmp = tmp[!grepl('resight', tolower(as.character(tmp$comments))),]
  
  # select important columns
  tmp = tmp[,c('time', 'lat', 'lon', 'species', 'number')]
  
  # add metadata
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$date)
  tmp$year = year(tmp$date)
  tmp$score = 'sighted'
  tmp$platform = 'plane'
  tmp$name = 'dfo_twin_otter'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # add to list
  SIG[[i]] = tmp
  
  # catch null error
  if(is.null(SIG[[i]])){stop('Sightings in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
# if(length(SIG)!=length(flist)){stop('Not all sightings were processed!')}

# combine all flights
SIGS = do.call(rbind, SIG)

# remove strange characters in 'number' column
SIGS$number = gsub(pattern = '\\+', replacement = '', x = SIGS$number)
SIGS$number = gsub(pattern = '\`', replacement = '', x = SIGS$number)
SIGS$number = as.numeric(SIGS$number)

# config flight data
sig = config_observations(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))
