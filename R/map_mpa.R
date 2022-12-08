## proc_mpa ##

# input -------------------------------------------------------------------

data_dir = 'data/raw/mpa/'

output_dir = 'data/processed/'

# process -----------------------------------------------------------------

#HMP test comment
# read in data
mpa = read.csv(paste0(data_dir, 'mpa.csv'))

# test with leaflet
# library(leaflet)
# leaflet(mpa) %>%
#   addTiles() %>%
#   addPolygons(~lon, ~lat, weight = .5)

# save for use in the app
saveRDS(mpa, file = paste0(output_dir, 'mpa.rds'))
