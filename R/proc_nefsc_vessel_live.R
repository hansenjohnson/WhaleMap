## proc_nefsc_vessel_live ##
# process sightings and tracklines from NEFSC vessel(s)

# input -------------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/nefsc_vessel/live/'

# directory for output
trk_ofile = 'data/interim/nefsc_vessel_live_eff.rds'
obs_ofile = 'data/interim/nefsc_vessel_live_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
source('R/proc_nefsc_vessel.R')

# process effort ----------------------------------------------------------

# tracks
tracks = proc_nefsc_vessel_effort(data_dir = data_dir)

# save tracks
saveRDS(tracks, trk_ofile)

# process sightings -------------------------------------------------------

# read in single sighting data file
obs_file = list.files(data_dir, pattern = "*Sightings.csv$", recursive = T, full.names = T)

if(length(obs_file)>=0){
  
  # read in data
  tmp = read.csv(obs_file, stringsAsFactors = F)
  
  # convert lat / lon
  tmp$lat = tmp$Lat
  tmp$lon = tmp$Long
  
  # wrangle time
  tmp$date = as.Date(tmp$Date, format = '%m/%d/%Y')
  tmp$time = as.POSIXct(paste0(tmp$date, ' ', tmp$Time), format = '%Y-%m-%d %H:%M', tz = 'America/New_York')
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  tmp$source = 'WhaleMap'
  
  # add deployment metadata
  tmp$name = tolower(tmp$Platform)
  tmp$platform = 'vessel'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # add sightings data
  tmp$species = 'right'
  tmp$number = tmp$SightingNumber
  tmp$calves = tmp$Calves..0.for.no.1.for.yes.
  
  tmp$score = 'possibly sighted'
  tmp$score[tmp$Confidence == 'Definite'] = 'sighted'
  
  # remove NAs
  tmp = tmp[!is.na(tmp$date),]
  
  # configure
  obs = config_observations(tmp)
  
} else {
  
  # data frame empty
  obs = config_observations(data.frame())
}

# save sightings
saveRDS(obs, obs_ofile)
