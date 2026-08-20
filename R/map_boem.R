# proc_boem #
# process energy development areas from BOEM

# input -------------------------------------------------------------------

# output directory
ofile = 'data/processed/boem.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(tidyverse))

# process -----------------------------------------------------------------

# wind lease area outlines: https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data
wind_lease = st_read('data/raw/gis/boem/boem-renewable-energy-shapefiles_0/osw_outlines/', quiet = TRUE) %>%
  filter(!st_is_empty(geometry)) %>%
  transmute(info = LEASE_NU_1, geometry) %>%
  group_by(info) %>%
  mutate(max_x = max(data.frame(st_coordinates(geometry))$X,na.rm=T)) %>%
  ungroup() %>%
  filter(max_x >= -85) %>%
  select(-max_x)

# virginia rfi outlines: https://www.boem.gov/marine-minerals/critical-minerals/virginia-mineral-activities
# st_layers('data/raw/gis/boem/VA_RFI_Area.gdb/')
virginia_rfi = st_read('data/raw/gis/boem/VA_RFI_Area.gdb/', layer = 'Virginia_RFI_Area') %>%
  mutate(info = 'Virginia Mineral Lease RFI') %>%
  st_transform(crs = "+proj=longlat +datum=WGS84")

# # plot to test
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addPolygons(data = wind_lease, color = 'red', popup = ~paste0(info), weight = 2) %>%
#   addPolygons(data = virginia_rfi, color = 'green', popup = ~paste0(info), weight = 2)

# save
save(wind_lease, virginia_rfi, file = ofile)
