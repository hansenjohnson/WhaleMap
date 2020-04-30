# proc_gis #
# process GIS data (management areas, critical habitats, etc.)

# input -------------------------------------------------------------------

# input directory
gis_dir = 'data/raw/2020_whalemapdata/GIS_data/'

# output directory
output_dir = 'data/processed/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tidyverse))

# common projection
ref = "+proj=longlat +init=epsg:3857"

# process -----------------------------------------------------------------

# read shipping data from TC
tc_zone = readOGR(paste0(gis_dir, '/TC 2020/')) %>%
  spTransform(ref)

# read fishing data from DFO
dfo_zone = readOGR(paste0(gis_dir, '/2020 DFO management measures/')) %>%
  spTransform(ref)

# read crtical habitat zone
critical_habitat_zone = readOGR(paste0(gis_dir, '/critical_habitat_zone/')) %>%
  spTransform(ref)

# # test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('tc_zone',
#                       'dfo_zone',
#                       'full_grid',
#                       'habitat_zone')
#     ) %>%
#   addPolygons(data = tc_zone, color = 'blue', popup = ~paste0(ID),
#                group = 'tc_zone',weight = 2) %>%
#   addPolygons(data = dfo_zone, color = 'orange',
#               group = 'dfo_zone',weight = 2) %>%
#   addPolygons(data = habitat_zone, color = 'darkgreen',
#               group = 'habitat_zone', weight = 2)

# save
save(tc_zone,
     dfo_zone,
     critical_habitat_zone,
     file = paste0(output_dir, 'gis.rda'))
