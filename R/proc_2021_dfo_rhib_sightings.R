## proc_2021_dfo_rhib_sightings ##
# Process sightings data from DFO rhib survey vessels

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2021_whalemapdata/DFO_RHIB/'

# output file name
ofile = 'data/interim/2021_dfo_rhib_sightings.rds'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(readxl))

# functions
source('R/functions.R')

# list files to process
flist = list.files(data_dir, pattern = '^2021_*.*_Sightings.xlsx$', full.names = T, recursive = T)

# only proceed if sightings files exist
if(length(flist)!=0){
  
  # list to hold loop output
  SIG = vector('list', length = length(flist))
  
  # read and format data ----------------------------------------------------
  
  # read files
  for(i in seq_along(flist)){
    
    # read in data
    tmp = read_excel(flist[i]) %>%
      as.data.frame()
    
    # if sightings exist
    if(nrow(tmp)!=0){
      
      # format
      tmp = tmp %>%
        transmute(
          date = as.Date(`Date (MM/DD/YYYY)`, format = '%m/%d/%Y'),
          time = as.POSIXct(paste0(date, ' ', format(`Time (UTC)`, '%H:%M:%S')), tz = 'UTC'),
          lat = as.numeric(`Latitude (Decimal degree)`),
          lon = as.numeric(`Longitude (Decimal degree)`),
          species = 'right',
          number = as.numeric(`Number in group`),
          yday = yday(date),
          year = year(date),
          calves = as.numeric(Calves),
          score = `Verified? (Yes/No)`,
          name = paste0('dfo_', tolower(Platform)),
          platform = 'vessel',
          id = paste(date, platform, name, sep = '_')
        ) 
      
      # fix score
      tmp$score[tmp$score == 'Yes'] = 'sighted'
      tmp$score[tmp$score == 'No'] = 'possibly sighted'
      
    }
    
    # add to list
    SIG[[i]] = tmp
    
  }
}

# combine and save --------------------------------------------------------

# combine all surveys
SIGS = bind_rows(SIG)

# configure data
sig = config_observations(SIGS)

# save
saveRDS(sig, ofile)
