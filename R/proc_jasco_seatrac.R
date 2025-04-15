## proc_jasco_seatrac ##
# process data from a JASCO seatrac test

# input -------------------------------------------------------------------

# observation file
obs_ifile = 'data/raw/jasco/seatrac/whaleMapReport_entireTrial.xlsx'

# track file
eff_ifile = 'data/raw/jasco/seatrac/SeaTrac_trial_tracks_latlong.xlsx'

# output files
obs_ofile = 'data/interim/jasco_seatrac_obs.rds'
eff_ofile = 'data/interim/jasco_seatrac_eff.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
library(readxl)

# detections --------------------------------------------------------------

# read in obs file
obs = read_excel(obs_ifile) %>%
  transmute(
    time = `UTC time`,
    date = date(time),
    year = year(date),
    yday = yday(date),
    lat = latitude,
    lon = longitude,
    species,
    score = `species id confidence`,
    number = NA,
    calves = NA,
    name = `platform name`,
    platform = 'vessel',
    source = 'WhaleMap'
  )

# fix name
obs$name = tolower(gsub(pattern = ' ', replacement = '-', obs$name))

# fix score
obs$score[obs$score == 'definitie acoustic'] = 'definite acoustic'

# fix species
obs$species[obs$species == 'Right whale'] = 'right'
obs$species[obs$species == 'Fin whale'] = 'fin'
obs$species[obs$species == 'Humpback whale'] = 'humpback'
obs$species[obs$species == 'Sei whale'] = 'sei'

# add id
obs$id = paste(min(obs$date), obs$platform, obs$name, sep = '_')

# config data types
OBS = config_observations(obs)

# save
saveRDS(OBS, file = obs_ofile)

# effort ------------------------------------------------------------------

# read in obs file
eff = read_excel(eff_ifile) %>%
  transmute(
    time = BoatTime,
    date = date(time),
    year = year(date),
    yday = yday(date),
    lat,
    lon,
    speed = NA,
    altitude = NA,
    platform = as.character(OBS$platform[1]),
    name = as.character(OBS$name[1]),
    id = as.character(OBS$id[1]),
    source = 'WhaleMap'
  )

# config data types
EFF = config_tracks(eff)

# save
saveRDS(EFF, file = eff_ofile)