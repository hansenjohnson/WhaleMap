# process and save all historical sightings

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/historical/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('functions/config_data.R')

# read in data ------------------------------------------------------------

# path to raw excel file
raw_excel = paste0(data_dir, 'CANADA14.xlsx')

# path to raw rds file (converted from excel for faster loading)
raw_rds = paste0(data_dir, 'CANADA14.rds')

# convert raw data
if(!file.exists(raw_rds)){
  library(readxl)
  raw = read_xlsx(raw_excel, sheet = 1)
  saveRDS(raw, raw_rds)
}

# read in data
all = readRDS(raw_rds)

# inspect data ------------------------------------------------------------

# # column                           # NOTES
# unique(all$MONTH)                  # month 13?
# unique(all$DAY)                    # day 0?
# unique(all$YEAR)                   # normal
# unique(all$TIME)                   # zeros and '.'
# summary(all$LATITUDE)              # normal
# summary(all$LONGITUDE)             # normal
# unique(all$DATATYPE)               # "opport" "shipbd" "aerial"
# unique(all$SPECCODE)               # "RIWH" "FIWH" "BLWH" "HUWH" "SEWH" "UNFS" NA     "UNBA" "BOWH"
# summary(as.factor(all$SPECCODE))   # mostly NAs, which makes me suspect there's a lot of effort data here...
# summary(all$NUMBER)                # normal
# unique(all$`CALF?`)                # "NO"  "YES" NA 
# unique(all$`FEED?`)                # "NO"  "YES" NA 
# unique(all$`SAG?`)                 # "NO"  "YES" NA 
# unique(all$`WHALER?`)              # "NO"  "YES" NA 
# unique(all$LEGTYPE)                # "." "5" "6" "2" "3" "4" "1" "7" "0" NA 
# unique(all$LEGSTAGE)               # "." "2" "5" "1" "0" "3" "4" "6" NA 
# unique(all$IDREL)                  # 3  2  1  9 NA
# unique(all$VISIBILITY)             # environmentals
# unique(all$BEAUFORT)               # sea state
# summary(all$SIGHTNO)               # sighting number (NA is effort)
# summary(all$EVENTNO)               # event number (includes both sightings and events)
# unique(all$FILEID)                 # file ID

# drop unused columns by name (do first to reduce data dims)
# all$FILEID = NULL
all$EVENTNO = NULL
all$ALTITUDE = NULL
all$BEAUFORT = NULL
all$OLDVIZ = NULL
all$VISIBILITY = NULL
all$SIGHTNO = NULL

# configure time ----------------------------------------------------------

# remove month 13s
all = all[-which(all$MONTH == 13),]

# set unknown days to the first day of each month
all$DAY[all$DAY == 0] = 1

# make date column
all$date = as.Date(paste0(all$YEAR, '-', all$MONTH, '-', all$DAY), format = '%Y-%m-%d')

# make time column
all$time = as.POSIXct(paste0(all$YEAR, '-', all$MONTH, '-', all$DAY, ' ', all$TIME),
                      format = '%Y-%m-%d %H%M%S', tz = 'UTC', usetz = T)

# calculate yday
all$yday = yday(all$date)

# calculate year
all$year = year(all$date)

# configure metadata ------------------------------------------------------

# species codes
all$species = NA

all$species[all$SPECCODE == 'RIWH'] = 'right'
all$species[all$SPECCODE == 'FIWH'] = 'fin'
all$species[all$SPECCODE == 'HUWH'] = 'humpback'
all$species[all$SPECCODE == 'BLWH'] = 'blue'
all$species[all$SPECCODE == 'SEWH'] = 'sei'
all$species[all$SPECCODE == 'BOWH'] = 'bowhead'
all$species[all$SPECCODE %in% c("UNFS", "UNBA")] = 'unidentified'

# platform
all$platform = NA

all$platform[all$DATATYPE == 'opport'] = 'opportunistic'
all$platform[all$DATATYPE == 'shipbd'] = 'vessel'
all$platform[all$DATATYPE == 'aerial'] = 'plane'

# name
all$name = paste0('narwc-', all$FILEID)

# remove file ID column
all$FILEID = NULL

# id
all$id = paste0(all$date, '_', all$platform, '_', all$name)

# effort ------------------------------------------------------------------

# find start and end of surveys
ind = which(all$LEGSTAGE==1|all$LEGSTAGE==5) 

# replace these lat lons with NAs to stop plotting
all$LATITUDE[ind] = NA 
all$LONGITUDE[ind] = NA

# take only on effort tracklines
tracks = all[which(all$LEGSTAGE==1 | all$LEGSTAGE==5 | all$LEGSTAGE==2),]

# fix lat lons
tracks$lat = tracks$LATITUDE
tracks$lon = tracks$LONGITUDE

# remove unused columns
tracks = tracks[,-c(1:17)]

# remove NAs
tracks = tracks[-which(is.na(tracks$time)),]

# remove species column
tracks$species = NULL

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, 'narwc_tracks.rds'))

# sightings ---------------------------------------------------------------

# isolate sightings
sig = all[which(!is.na(all$species)),]

# get lat lons
sig$lat = sig$LATITUDE
sig$lon = sig$LONGITUDE

# get number of individuals
sig$number = sig$NUMBER

# get score
sig$score = NA
sig$score[which(sig$number>0)] = 'sighted'

# remove unused columns
sig = sig[,-c(1:17)]

# remove NAs
sig = sig[-which(is.na(sig$score)),]

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, paste0(output_dir, 'narwc_sightings.rds'))
