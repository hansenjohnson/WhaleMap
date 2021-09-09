## proc_unb_sightings ##
# process opportunistic sightings from UNB surveys

# input -------------------------------------------------------------------

# input file
data_dir = 'data/raw/unb/'

# directory for output
ofile = 'data/interim/unb_sightings.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')

# process data ------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = '*.*-sightings.csv$', full.names = T, recursive = T)

# list to hold loop output
SIG = vector('list', length = length(flist))

# read files
for(ii in seq_along(flist)){
  
  # read in spp and obs keys
  tmp = read_csv(flist[ii], col_types = cols()) %>%
    rename(
      lat = contains('Latitude', ignore.case = TRUE),
      lon = contains('Longitude', ignore.case = TRUE)
    ) %>%
    transmute(
      date = as.Date(`Date (YYYY-MM-DD)`),
      yday = yday(date),
      year = year(date),
      time = as.POSIXct(paste0(as.character(date), ' ', `Time (UTC)`, ' UTC')),
      lat,
      lon,
      species = Species,
      number = Number,
      calves = Calves,
      score = Score,
      platform = 'opportunistic',
      name = 'UNB',
      id = paste0(date, '_', platform, '_', name),
      source = 'WhaleMap'
    )
  
  # determine ll type
  ll_ddm = grep(pattern = ' ', x = tmp$lat[1])
  
  # convert if necessary
  if(length(ll_ddm)>0){
    tmp$lat = ddm2dd_col(tmp$lat)  
    tmp$lon = abs(ddm2dd_col(tmp$lon))*-1
  }
  
  # check for errors
  if(TRUE %in% is.na(c(tmp$lon,tmp$lat))){
    warning('Position error detected in file: ', flist[ii])
  }
  
  # add data to list
  SIG[[ii]] = tmp
}

# combine
sig = bind_rows(SIG)

# fix scores
sig$score[sig$score == 'definite'] = 'sighted'
sig$score[sig$score %in% c('probable', 'possible')] = 'possibly sighted'

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, ofile)
