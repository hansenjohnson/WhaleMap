# process and save 2017 right whale sightings

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2017_sightings/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate)

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

# clean up data
noaa = clean_latlon(noaa)
she = clean_latlon(she)
tc = clean_latlon(tc)
cnp = clean_latlon(cnp)

# add noaa metadata
noaa$platform = 'plane'
noaa$name = 'noaa'
noaa$id = paste0(noaa$date, '_plane_noaa')

# add shelagh metadata
she$platform = 'vessel'
she$name = 'shelagh'
she$id = paste0(she$date, '_vessel_shelagh')

# add transport canada metadata
tc$platform = 'plane'
tc$name = 'tc'
tc$id = paste0(tc$date, '_plane_tc')

# add CnP metadata
cnp$platform = 'plane'
cnp$name = 'cnp'
cnp$id = paste0(cnp$date, '_plane_cnp')

# save
saveRDS(noaa, paste0(output_dir, '2017_noaa_sightings.rds'))
saveRDS(she, paste0(output_dir, '2017_shelagh_sightings.rds'))
saveRDS(tc, paste0(output_dir, '2017_tc_sightings.rds'))
saveRDS(cnp, paste0(output_dir, '2017_cnp_sightings.rds'))