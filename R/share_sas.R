## share_sas ##
# share data with NOAA NEFSC

# input -------------------------------------------------------------------

# input files
obs_file = 'data/processed/observations.rds'
to_sas_dir = 'shared/sas/'

# list WhaleMap platform names to not send from WhaleMap to NOAA NEFSC
no_send_list = c('noaa_twin_otter')

# setup -------------------------------------------------------------------

# libraries
source('R/functions.R')

# define start and end times of subset
t1 = Sys.Date()
t0 = t1 - 365

# make output dir
if(!dir.exists(to_sas_dir)){dir.create(to_sas_dir, recursive = TRUE)}

# compare sas whalemap ----------------------------------------------------

# read in whalemap observations
obs = readRDS(obs_file) 

# add identifier
obs$whalemap_id = seq(1, nrow(obs),1)

# filter whalemap data
obs = obs %>%
  filter(date >= t0 & date <= t1 & 
           species == 'right' & !is.na(lat) & !is.na(lon) & 
           !grepl('SAS-', name) &
           !(name %in% no_send_list) & source != 'NARWC')

# write output -----------------------------------------------------------

if(plot_sas){
  # whalemap
  saveRDS(object = to_keep, file = keep_sas_file)
}

# sas
write.csv(x = to_send, file = paste0(to_sas_dir, 'whalemap-data.csv'), row.names = FALSE)
