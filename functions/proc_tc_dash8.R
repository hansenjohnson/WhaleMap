## tc_dash8 ##
# Process gps data from the Transport Canada Dash-8 survey plane, and save it in a consistent format. It is important to note that these data are 'ugly'. They were recorded in different formats over the course of the season, and each format requires special treatment to coerce it into the standard form used here.

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/tc_dash8_tracks/'

# output directory
output_dir = 'data/interim/'

# plot tracks?
plot_tracks = F

# setup -------------------------------------------------------------------

# libraries
library(lubridate, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(tools, quietly = T, warn.conflicts = F)

# functions
source('functions/config_data.R')
source('functions/roundTen.R')
source('functions/subsample_gps.R')
source('functions/plot_save_track.R')

# list files to process
flist = list.files(data_dir, pattern = '.csv', full.names = T)

# specify column names
cnames = c('time', 'lon', 'lat', 'speed', 'altitude')

# list to hold loop output
TRK = list()

# read and format data ----------------------------------------------------

# read files
for(i in seq_along(flist)){
  
  # format: 'TC Flight 20170808 gps.csv'
  if(grepl(pattern = 'TC Flight (\\d{8})', x = flist[i])){
    
    # read in file
    tmp = read.csv(flist[i])
    
    # select and rename important columns
    tmp = data.frame(tmp$Ti, tmp$Lo, tmp$La, tmp$Gr, tmp$Al)
    colnames(tmp) = cnames
    
    # correct for variable precision (or errors) in gps
    f = roundTen(tmp$time)/10^9
    tmp$time = tmp$time/f
    
    # remove columns without timestamp
    tmp = tmp[which(!is.na(tmp$time)),]
    
    # add timestamp
    tmp$time = as.POSIXct(tmp$time, origin = '1970-01-01', tz = 'UTC')
    
    # format: 'MART_Dash8_tracks_2017-12-29.csv'
  } else if(grepl(pattern = 'MART_Dash8_tracks_(\\d{4}).(\\d{2}).(\\d{2}).csv', x = flist[i], ignore.case = T)){
    
    # read in file
    tmp = read.csv(flist[i], skip = 2)
    
    # select and rename important columns
    tmp = data.frame(tmp$Timestamp, tmp$Longitude, tmp$Latitude, tmp$Speed, tmp$Altitude)
    colnames(tmp) = cnames
    
    # Correct for variable precision (or errors) in gps
    f = roundTen(tmp$time)/10^9
    tmp$time = tmp$time/f
    
    # add timestamp
    tmp$time = as.POSIXct(tmp$time, origin = '1970-01-01', tz = 'UTC')
    
  # format: 'MART_Flights_31-08-2017_GPS.csv' or 'MART_Flights_22_08_2015_GPS.csv'
  } else if(grepl(pattern = 'MART_Flights_(\\d{2}).(\\d{2}).(\\d{4})_GPS.csv', x = flist[i], ignore.case = T)){
    
    # read in file
    tmp = read.csv(flist[i])
    
    # add dummy speed column
    tmp$speed = NA
    
    # select and rename important columns
    tmp = data.frame(tmp$time, tmp$lon, tmp$lat, tmp$speed, tmp$ele)
    colnames(tmp) = cnames
    
    # add timestamp
    tmp$time = as.POSIXct(tmp$time, format = '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
  
  # format: 'September06_1of3.csv'  
  } else if(grepl(pattern = 'September(\\d{2})*', x = flist[i])){
    
    # read in file
    tmp = read.csv(flist[i], skip = 2)
    
    # select and rename important columns
    tmp = data.frame(tmp$Timestamp, tmp$Longitude, tmp$Latitude, tmp$Speed, tmp$Altitude)
    colnames(tmp) = cnames
    
    # Correct for variable precision (or errors) in gps
    f = roundTen(tmp$time)/10^9
    tmp$time = tmp$time/f
    
    # add timestamp
    tmp$time = as.POSIXct(tmp$time, origin = '1970-01-01', tz = 'UTC')
  
  # format: '20171212tracklog (47).csv' or '20171105_tracklog.csv'
  } else if(grepl(pattern = '(\\d{8})*tracklog', x = flist[i])){
    
    # read in file
    tmp = read.csv(flist[i], skip = 2)
    
    # select and rename important columns
    tmp = data.frame(tmp$Timestamp, tmp$Longitude, tmp$Latitude, tmp$Speed, tmp$Altitude)
    colnames(tmp) = cnames
    
    # Correct for variable precision (or errors) in gps
    f = roundTen(tmp$time)/10^9
    tmp$time = tmp$time/f
    
    # add timestamp
    tmp$time = as.POSIXct(tmp$time, origin = '1970-01-01', tz = 'UTC')
  
  # format: 'TC_FLight_19-08-2017_Leg1.csv'  
  } else if(grepl(pattern = '(TC_Flight_(\\d{2})-(\\d{2})-(\\d{4}))', x = flist[i], ignore.case = T)){
    
    # read in file
    tmp = read.csv(flist[i])
    
    # select and rename important columns
    tmp = data.frame(tmp$Date.and.Time, tmp$Longitude, tmp$Latitude, tmp$Speed, tmp$Altitude)
    colnames(tmp) = cnames
    
    # add timestamp
    tmp$time = as.POSIXct(as.character(tmp$time), format = '%d-%m-%Y %H:%M:%S', tz = 'UTC')
  
  # format: 'TC_FLights_09-08-2017_GPS.csv'  
  } else if(grepl(pattern = '(TC_Flights_(\\d{2})-(\\d{2})-(\\d{4}))_GPS.csv', x = flist[i], ignore.case = T)){

    # read in file
    tmp = read.csv(flist[i])
    
    # correct filename
    if(basename(flist[i])=='TC_FLights_09-08-2017_GPS.csv'){
      colnames(tmp)[7] = 'Longitude'
    }
    
    # select and rename important columns
    tmp = data.frame(tmp$Date.and.Time, tmp$Longitude, tmp$Latitude, tmp$Speed..knots., tmp$Altitude)
    colnames(tmp) = cnames
    
    # add timestamp
    tmp$time = as.POSIXct(as.character(tmp$time), format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
    
  } else {
    stop('Format not known!')
  }
  
  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = tmp)
  
  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'plane'
  tracks$name = 'tc'
  tracks$id = paste0(tracks$date, '_plane_tc')
  
  # plot track
  if(plot_tracks){
    plot_save_track(tracks, flist[i])
  }
  
  # add to list
  TRK[[i]] = tracks
  
  # catch null error
  if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
  
}

# combine and save --------------------------------------------------------

# catch errors
if(length(TRK)!=length(flist)){stop('Not all tracks were processed!')}

# combine all flights
TRACKS = do.call(rbind, TRK)

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, 'tc_dash8_tracks.rds'))

