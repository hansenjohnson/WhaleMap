## proc_narwc ##
# process historical NARWC observations

# input -------------------------------------------------------------------

# input file
ifile = 'data/raw/narwc/HANSEN21.CSV'

# output file
ofile = 'data/interim/narwc_obs.rds'

# earliest year
yr = 2010

# setup -------------------------------------------------------------------

library(tidyverse)
library(lubridate)
source('R/functions.R')

# process -----------------------------------------------------------------

# read in data
all = read.csv(ifile, as.is = TRUE)

# remove month 13s
all = all[-which(all$MONTH == 13),]

# make date column
all$date = as.Date(paste0(all$YEAR, '-', all$MONTH, '-', all$DAY), format = '%Y-%m-%d')

# make time column
all$time = as.POSIXct(paste0(all$YEAR, '-', all$MONTH, '-', all$DAY, ' ', all$TIME),
                      format = '%Y-%m-%d %H%M%S', tz = 'UTC', usetz = T)

# calculate yday
all$yday = yday(all$date)

# calculate year
all$year = year(all$date)

# lat lon
all$lat = as.numeric(all$LAT_DD)
all$lon = as.numeric(all$LONG_DD)

# species codes
all$species = NA
all$species[all$SPECCODE == 'RIWH'] = 'right'
all$species[all$SPECCODE == 'FIWH'] = 'fin'
all$species[all$SPECCODE == 'HUWH'] = 'humpback'
all$species[all$SPECCODE == 'BLWH'] = 'blue'
all$species[all$SPECCODE == 'SEWH'] = 'sei'

# number
all$number = as.numeric(all$NUMBER)

# calves
all$calves = as.numeric(all$NUMCALF)

# score
all$score = NA
all$score[all$IDREL %in% c(1,2,9)] = 'possibly sighted'
all$score[all$IDREL == 3] = 'sighted'

# platform
all$platform = NA
all$platform[all$DATATYPE == 'opport'] = 'opportunistic'
all$platform[all$DATATYPE == 'shipbd'] = 'vessel'
all$platform[all$DATATYPE == 'aerial'] = 'plane'

# define name
all$name = paste0('NARWC-', all$DDSOURCE)

# id
all$id = all$FILEID

# filters 
all = subset(all, WHLR == ' NO' & DEAD == ' NO')
all = subset(all, !is.na(date) & !is.na(species) & !is.na(lat) & !is.na(lon))
all = subset(all, year >= yr)

# configure observations
rwc = config_observations(all)

# add source
rwc$source = 'NARWC'

# save
saveRDS(rwc, ofile)
