## proc_2021_tc_rpas_sightings ##
# Process observations data from TC RPAS survey

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2021_whalemapdata/TC_RPAS/'

# output file name
ofile = 'data/interim/2021_tc_rpas_sightings.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# tracks ------------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = '^(\\d{8})_RPAS_sightings-template.csv$', full.names = T, recursive = T)

# list to hold loop output
SIG = vector('list', length = length(flist))

# read files
for(ii in seq_along(flist)){
  
  # read in file
  tmp = read_csv(flist[ii], col_types = cols()) %>%
    transmute(
      date = Date_UTC,
      time = Time_UTC,
      lat = ddm2dd_col(Pos_lat),
      lon = -ddm2dd_col(Pos_long),
      species = NA,
      score = 'sighted',
      number = Nb_total,
      Sp_code = tolower(Sp_code),
      calves,
      yday = yday(date),
      year = year(date),
      platform = 'rpas',
      name = 'tc_rpas',
      id = paste(date, platform, name, sep = '_'),
      source = 'WhaleMap'
    )
  
  # fix species names
  tmp$species[tmp$Sp_code == 'eg'] = 'right'
  tmp$species[tmp$Sp_code == 'bm'] = 'blue'
  tmp$species[tmp$Sp_code == 'bp'] = 'fin'
  tmp$species[tmp$Sp_code == 'bb'] = 'sei'
  tmp$species[tmp$Sp_code == 'mn'] = 'humpback'
  tmp$Sp_code = NULL
  
  # add to list
  SIG[[ii]] = tmp
}

## combine
SIGHTINGS = bind_rows(SIG)

# config flight data
sightings = config_observations(SIGHTINGS)

# save
saveRDS(sightings, ofile)
