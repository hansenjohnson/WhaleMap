# process and save 2017 right whale sightings

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/2017_sightings/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

library(lubridate, quietly = T, warn.conflicts = F)
source('functions/config_data.R')
source('functions/clean_latlon.R')

# define functions --------------------------------------------------------

# clean and save data
clean_sig = function(subs, platform, name){

  # clean up data
  subs = clean_latlon(subs)

  # add metadata
  subs$platform = platform
  subs$name = name
  subs$id = paste0(subs$date, '_', platform, '_', subs$name)

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

# convert number to numeric
sig$number = as.character(sig$number)
sig$number = gsub(pattern = "\\?", replacement = NA, x = sig$number)
sig$number = as.numeric(sig$number)

# survey data -------------------------------------------------------------

# isolate survey data
noaa = sig[sig$platform=='NOAA Twin Otter',]
she = sig[sig$platform=='CWI- the Shelagh',]
tc = sig[sig$platform=='TC-Dash 8',]
cnp = sig[sig$platform=='C&P plane (DFO)'|sig$platform=='C&P plane',]
dfo = sig[sig$platform=='DFO Twin Otter',]
neaq = sig[sig$platform=='Nereid -NEAq',]
mics = sig[sig$platform=='MICS',]

# clean and save survey data
clean_sig(noaa, 'plane', 'noaa_twin_otter')
clean_sig(she, 'vessel', 'shelagh')
clean_sig(tc, 'plane', 'tc_dash8')
clean_sig(cnp, 'plane', 'cnp')
clean_sig(dfo, 'plane', 'dfo_twin_otter')
clean_sig(neaq, 'vessel', 'nereid')
clean_sig(mics, 'vessel', 'mics')

# opportunistic data ------------------------------------------------------

# isolate opportunistic data
opp = sig[sig$platform!='NOAA Twin Otter' & 
            sig$platform!='CWI- the Shelagh' &
            sig$platform!='TC-Dash 8' &
            sig$platform!='C&P plane (DFO)' &
            sig$platform!='C&P plane' &
            sig$platform!='DFO Twin Otter' &
            sig$platform!='Nereid -NEAq' &
            sig$platform!='MICS',]

# clean and save opportunistic data

# clean lat lons
opp = clean_latlon(opp)

# remove nas
opp = opp[-c(which(is.na(opp$lat))),]

# add metadata
opp$name = opp$platform
opp$platform = 'opportunistic'
opp$id = paste0(opp$date, '_', opp$platform, '_', opp$name)
opp$score = 'possibly sighted'

# config data types
opp = config_observations(opp)

# save
saveRDS(opp, paste0(output_dir, '2017_opportunistic_sightings.rds'))
