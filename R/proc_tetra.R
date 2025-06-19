## proc_tetra ##
# process data from tetra tech

# input -------------------------------------------------------------------

# raw data folder
data_dir = 'data/raw/tetra/'

# output files
eff_ofile = 'data/interim/tetra_eff.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# extract -----------------------------------------------------------------

# check for compressed data directories
zdirs = list.files(data_dir, pattern = "*.zip$", full.names = T, recursive = T)

for(ii in seq_along(zdirs)){
  unzip(zdirs[ii], exdir = data_dir)
}

# effort ------------------------------------------------------------------

# list files
flist = list.files(data_dir, pattern = "*.csv$", full.names = T, recursive = T)

# read through
EFF = vector('list', length = length(flist))
for(ii in seq_along(flist)){
  
  # read data
  eff = read_csv(flist[ii], show_col_types = FALSE) %>%
    transmute(
      time = `Time Created (UTC)`,
      date = date(time),
      yday = yday(date),
      year = year(date),
      lat = Latitude,
      lon = Longitude,
      platform = "plane",
      name = "tetra",
      id = paste(date, platform, name, sep = '_'),
      source = "WhaleMap"
    ) %>%
    as.data.frame()
  
  # configure
  EFF[[ii]] = config_tracks(eff)
}

# combine
effort = bind_rows(EFF)

# save effort
saveRDS(effort, eff_ofile)

# # quick check
# ggplot(effort)+
#   geom_path(aes(x = lon, y = lat))+
#   facet_wrap(~id)+
#   coord_quickmap()+
#   theme_bw()

# obs ---------------------------------------------------------------------

## observations currently submitted separately to RWSAS ##

