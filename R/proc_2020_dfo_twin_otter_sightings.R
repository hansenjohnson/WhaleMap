## proc_2020_dfo_twin_otter_sightings ##
# Process sightings data from DFO twin otter survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2020_whalemapdata/DFO_twin_otter/'

# output file name
ofile = '2020_dfo_twin_otter_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(readxl))

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = 'xls$', full.names = T, recursive = T)

# only proceed if sightings files exist
if(length(flist)!=0){
  
  # list to hold loop output
  SIG = vector('list', length = length(flist))
  
  # read and format data ----------------------------------------------------
  
  # read files
  for(i in seq_along(flist)){
    
    # skip empty files
    if (file.size(flist[i]) == 0) next
    
    # read in data
    tmp = read_excel('~/Desktop/20200520.xlsx') %>%
      transmute(
        date = as.Date(date_UTC),
        time = as.POSIXct(paste0(date, ' ', format(time_UTC, '%H:%M:%S')), tz = 'UTC'),
        lat = lat,
        lon = long,
        species = sp_code,
        number = nb_tot,
        yday = yday(date),
        year = year(date),
        score = 'sighted',
        platform = 'plane',
        name = 'dfo_twin_otter',
        id = paste(date, platform, name, sep = '_')
      ) %>%
      as.data.frame()
    
    # add species identifiers
    tmp$species = toupper(tmp$species)
    tmp$species[tmp$species == 'EG'] = 'right'
    tmp$species[tmp$species == 'MN'] = 'humpback'
    tmp$species[tmp$species == 'BB'] = 'sei'
    tmp$species[tmp$species == 'BP'] = 'fin'
    tmp$species[tmp$species == 'FS'] = 'fin/sei'
    tmp$species[tmp$species == 'BA'] = 'minke'
    tmp$species[tmp$species == 'BM'] = 'blue'
    tmp$species[tmp$species == 'LWNR'] = 'unknown rorqual'
    tmp$species[tmp$species == 'UnWh'] = 'unknown large whale'
    tmp$species[tmp$species == 'UC'] = 'unknown cetacean'
    
    # add to list
    SIG[[i]] = tmp
    
    # catch null error
    if(is.null(SIG[[i]])){stop('Sightings in ', flist[i], ' not processed correctly!')}
    
  }
  
  # combine and save --------------------------------------------------------
  
  # combine all flights
  SIGS = bind_rows(SIG)
  
} else { # if no sightings files exist
  
  # make empty data frame
  SIGS = data.frame()
}

# config flight data
sig = config_observations(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))
