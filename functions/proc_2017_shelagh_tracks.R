# process and save all shelagh tracklines from 2017

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2017_shelagh_tracks/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('functions/config_data.R')

# list data files
dfiles = list.files(data_dir, pattern = '*CWI-V*', full.names = T)

SHE = list()
for(i in seq_along(dfiles)){
  
  # determine filename
  ifile = dfiles[i]
  
  # read in data
  SHE[[i]] = read.csv(ifile)
}

# combine into single table
she = do.call(rbind.data.frame, SHE)

# fill in legstage info ---------------------------------------------------

# identify start and end rows when 'on effort'
effort = cbind(which(she$LEGSTAGE...ENVIRONMENTALS == 1),
               which(she$LEGSTAGE...ENVIRONMENTALS == 5))

# fill in leg stage info
for(i in 1:nrow(effort)){
  she$LEGSTAGE...ENVIRONMENTALS[(effort[i,1]+1):(effort[i,2]-1)] = 2
}

# remove time with no effort
na_ind = which(is.na(she$LEGSTAGE...ENVIRONMENTALS))
she = she[-c(na_ind),]

# correct timestamps ------------------------------------------------------

# convert time to character
she$Time = as.character(she$Time)

# find and remove rows for environmentals that use UTC
utc_ind = grep('UTC', x = she$Time)
she = she[-c(utc_ind),]

# convert time
she$time = as.POSIXct(she$Time, tz = 'America/Halifax')

# convert time zone
she$time = as.POSIXct(format(she$time, tz = 'UTC'), tz = 'UTC')

# find start and end of surveys
ind = which(she$LEGSTAGE...ENVIRONMENTALS==1|she$LEGSTAGE...ENVIRONMENTALS==5) 

# replace these lat lons with NAs to stop plotting
she$TrkLatitude[ind] = NA 
she$TrkLongitude[ind] = NA

# wrangle time
she$date = as.Date(she$time)
she$yday = yday(she$time)
she$year = year(she$time)

# add deployment metadata
she$platform = 'vessel'
she$name = 'shelagh'
she$id = paste0(she$date, '_vessel_shelagh')

# tracks ------------------------------------------------------------------

# take only on effort tracklines
tracks = she[which(she$LEGSTAGE...ENVIRONMENTALS==1 | 
                     she$LEGSTAGE...ENVIRONMENTALS==5 | 
                     she$LEGSTAGE...ENVIRONMENTALS==2),]

# fix lat lons
tracks$lat = tracks$TrkLatitude
tracks$lon = tracks$TrkLongitude

# remove unused columns
tracks = tracks[,-c(1:47)]

# config data types
tracks = config_tracks(tracks)

# save
saveRDS(tracks, paste0(output_dir, '2017_shelagh_tracks.rds'))

