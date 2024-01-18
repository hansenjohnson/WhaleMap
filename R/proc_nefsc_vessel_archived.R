## proc_nefsc_vessel_archived ##
# process sightings and tracklines from NEFSC vessel(s)

# input -------------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/nefsc_vessel/archive/'

# directory for output
trk_ofile = 'data/interim/nefsc_vessel_archived_eff.rds'
obs_ofile = 'data/interim/nefsc_vessel_archived_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
source('R/proc_nefsc_vessel.R')

# process effort ----------------------------------------------------------

# tracks
tracks = proc_nefsc_vessel_effort(data_dir = data_dir)

# save tracks
saveRDS(tracks, trk_ofile)

# process sightings -------------------------------------------------------

# list sightings data files
olist = list.files(data_dir, pattern = "*sighttotal.csv$", recursive = T, full.names = T)

if(length(olist)>=0){
  OBS = vector('list', length = length(olist))
  for(io in seq_along(olist)){
    
    # read in data
    tmp = read.csv(olist[io], stringsAsFactors = F)
    
    # convert lat / lon
    tmp$lat = tmp$EntryLatitude
    tmp$lon = tmp$EntryLongitude
    
    # wrangle time
    tmp$date = as.Date(tmp$Date, format = '%d-%b-%y')
    tmp$time = as.POSIXct(paste0(tmp$date, ' ', tmp$EntryTime), format = '%Y-%m-%d %H:%M:%S', tz = 'UTC')
    tmp$yday = yday(tmp$time)
    tmp$year = year(tmp$time)
    tmp$source = 'WhaleMap'
    
    # add deployment metadata
    tmp$name = tolower(substr(basename(olist[io]), 0,3))
    tmp$platform = 'vessel'
    tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
    
    # add sightings data
    tmp$species = NA
    tmp$species[tmp$SpeciesCode == 'HUWH'] = 'humpback'
    tmp$species[tmp$SpeciesCode == 'RIWH'] = 'right'
    tmp$species[tmp$SpeciesCode == 'FIWH'] = 'fin'
    tmp$species[tmp$SpeciesCode == 'SEWH'] = 'sei'
    
    tmp$number = tmp$GroupSize
    tmp$calves = tmp$Calves
    tmp$calves[tmp$Calves < 0] = NA
    
    tmp$score = NA
    tmp$score[tmp$Confidence == 'certain'] = 'sighted'
    tmp$score[tmp$Confidence %in% c('probably', 'not sure')] = 'possibly sighted'
    
    # configure
    tmp = config_observations(tmp)
    OBS[[io]] = tmp[!is.na(tmp$species),]
  }
  
  # combine
  obs = bind_rows(OBS)
  
} else {
  
  # data frame empty
  obs = data.frame()
}

# format
observations = config_observations(obs)

# save sightings
saveRDS(observations, obs_ofile)

