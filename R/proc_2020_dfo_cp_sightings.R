## proc_2020_dfo_cp_sightings ##
# Process sightings data from DFO conservation and protection (cp) plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2020_whalemapdata/2020-C&P/'

# output file name
ofile = '2020_dfo_cp_sightings.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(readxl))

# functions
source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('Whale - Fin', 'Whale - Right', 'Whale - Minke', 'Whale - Sei', 'Whale - Humpback','Whale - Blue'),
  species = c('fin', 'right', 'minke', 'sei', 'humpback','blue'))

# process -----------------------------------------------------------------

# list files to process
flist = list.files(data_dir, pattern = '(\\d{8})_(*.*).xls$', full.names = T, recursive = T)

# list to hold loop output
SIG = vector('list', length = length(flist))

if(length(flist)!=0){
  
  # read files
  for(i in seq_along(flist)){
    
    # skip empty files
    if (file.size(flist[i]) == 0) next
    
    # read in file
    tmp = suppressMessages(read_excel(flist[i]))
    
    # determine start and end indices of data
    i0 = grep('ID', x = tmp[[1]])
    i1 = grep('record', x = tmp[[1]])
    
    # find bad columns (from excel formatting)
    bad_cols = which(is.na(tmp[i0,]))
    
    # subset good data
    idf = tmp[(i0+1):(i1-2),-bad_cols]
    
    # re-assign correct column names
    colnames(idf) = tmp[i0,-bad_cols]
    
    # check all have IDs
    if(length(which(is.na(idf$ID)))>0){
      warning('Problem with:', flist[i], '\nSome records do not have an ID')
    }
    
    # format
    sig = idf %>%
      separate(col = `Target Position`, into = c('lat','lon'), sep = ' ') %>%
      transmute(
        time = as.POSIXct(Create, format = '%m/%d %H:%M:%S', tz = 'UTC'),
        date = as.Date(time),
        year = year(time),
        yday = yday(time),
        lat = ddm2dd_col(lat),
        lon = -ddm2dd_col(lon),
        species = Species,
        number = No.,
        calves = NA,
        score = 'sighted',
        platform = 'plane',
        name = 'dfo_cp',
        id = paste(date, platform, name, sep = '_')
      )
    
    # find indecies of matching species codes
    mind = match(table = spp_key$code, x = sig$species)
    
    # replace codes with species names
    sig$species = spp_key$species[mind]
    
    # drop unknown codes
    sig = sig[which(!is.na(sig$species)),]
    
    # add to list
    SIG[[i]] = sig
  }
  
  # combine all flights
  SIGS = as.data.frame(bind_rows(SIG))
  
} else { # if no sightings files exist
  
  # make empty data frame
  SIGS = data.frame()
}

# config flight data
sig = config_observations(SIGS)

# save
saveRDS(sig, paste0(output_dir, ofile))
