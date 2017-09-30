# process and save 2017 right whale sightings

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2017_sightings/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate)
source('functions/config_data.R')

# define functions --------------------------------------------------------

clean_latlon = function(d){
  d$lat = as.character(d$lat)
  d$lat = gsub(",","",d$lat)
  d$lat = d$lat = gsub("^\\s","",d$lat)
  d$lat = as.numeric(d$lat)
  
  d$lon = as.character(d$lon)
  d$lon = gsub(",","",d$lon)
  d$lon = d$lon = gsub("^\\s","",d$lon)
  d$lon = as.numeric(d$lon)
  
  d$lon[which(d$lon>0)] = -d$lon[which(d$lon>0)]
  
  return(d)
}


# clean and save data
clean_sig = function(subs, platform, name){

  # clean up data
  subs = clean_latlon(subs)

  # add metadata
  subs$platform = platform
  subs$name = name
  subs$id = paste0(subs$date, '_', platform, '_', name)

  # config data types
  subs = config_observations(subs)
  
  # save
  saveRDS(subs, paste0(output_dir, '2017_', name, '_sightings.rds'))
}

# process data ------------------------------------------------------------

# read in spp and obs keys
sig = read.csv(paste0(data_dir, '/2017_narw_sightings.csv'))
colnames(sig) = c('date', 'time', 'lat', 'lon', 'number', 'platform', 'photos', 'notes')

# # remove columns without timestamps
# sig = sig[sig$time!='',]

# wrangle time
time = paste0(sig$date, ' ', sig$time)
sig$time = as.POSIXct(time, format = '%m/%d/%Y %H:%M:%S', tz = 'UTC', usetz=TRUE)

# wrangle date
sig$date = as.Date(sig$date, format = '%m/%d/%Y')
sig$yday = yday(sig$date)
sig$year = year(sig$date)
sig$score = 'sighted'
sig$species = 'right'

# remove columns
sig$photos = NULL
sig$notes = NULL

# isolate data
noaa = sig[sig$platform=='NOAA Twin Otter',]
she = sig[sig$platform=='CWI- the Shelagh',]
tc = sig[sig$platform=='TC-Dash 8',]
cnp = sig[sig$platform=='C&P plane (DFO)'|sig$platform=='C&P plane',]
dfo = sig[sig$platform=='DFO Twin Otter',]

# clean and save
clean_sig(noaa, 'plane', 'noaa')
clean_sig(she, 'vessel', 'shelagh')
clean_sig(tc, 'plane', 'tc')
clean_sig(cnp, 'plane', 'cnp')
clean_sig(dfo, 'plane', 'dfo')