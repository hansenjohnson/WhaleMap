# process polygons for plotting on map

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/map_polygons/'

# directory for output
output_dir = 'data/processed/'

# process -----------------------------------------------------------------

# read in data
map = read.csv(paste0(data_dir, 'map_polygons.csv'))

# convert to lat and lons
map$lat = map$lat_deg+map$lat_min/60
map$lon = -(map$lon_deg+map$lon_min/60)

# drop unused columns
map = map[,-c(1:4)]

# save output
saveRDS(map, paste0(output_dir, 'map_polygons.rds'))