## proc_2020_unb_sightings ##
# process 2020 dfo opportunistic sightings from UNB surveys

# input -------------------------------------------------------------------

# input file
data_dir = 'data/raw/2020_unb/'

# directory for output
ofile = 'data/interim/2020_unb_sightings.rds'

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
  SIG[[ii]] = read_csv(flist[ii], col_types = cols()) %>%
    transmute(
      date = as.Date(`Date (YYYY-MM-DD)`),
      yday = yday(date),
      year = year(date),
      time = as.POSIXct(paste0(as.character(date), ' ', `Time (UTC)`, ' UTC')),
      lat = `Latitude (Decimal degree)`,
      lon = `Longitude (Decimal degree)`,
      species = Species,
      number = Number,
      calves = Calves,
      score = Score,
      platform = 'opportunistic',
      name = 'UNB',
      id = paste0(date, '_', platform, '_', name)
    )
}

# combine
sig = bind_rows(SIG)

# fix scores
sig$score[sig$score == 'definite'] = 'sighted'
sig$score[sig$score == 'possible'] = 'possibly sighted'

# config data types
sig = config_observations(sig)

# save
saveRDS(sig, ofile)
