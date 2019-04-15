# proc_gis #
# process GIS data (management areas, critical habitats, etc.)

# input -------------------------------------------------------------------

# input directory
gis_dir = 'data/raw/2019_whalemapdata/GIS_data/'

# output directory
output_dir = 'data/processed/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tidyverse))

# common projection
ref = "+proj=longlat +init=epsg:3857"

# process -----------------------------------------------------------------

# read shipping data
static_shipping_zone = readOGR(paste0(gis_dir, '/static_shipping_zone/')) %>%
  spTransform(ref)
dynamic_shipping_zone = readOGR(paste0(gis_dir, '/dynamic_shipping_zone/')) %>%
  spTransform(ref)

# read fishing data
static_fishing_zone = readOGR(paste0(gis_dir, '/static_fishing_zone/')) %>%
  spTransform(ref)
dynamic_fishing_grid = readOGR(paste0(gis_dir, '/dynamic_fishing_grid/')) %>%
  spTransform(ref)
dynamic_fishing_zone = readOGR(paste0(gis_dir, '/dynamic_fishing_zone/')) %>%
  spTransform(ref)
dynamic_fishing_10_fathom_contour = readOGR(paste0(gis_dir, '/dynamic_fishing_10_fathom_contour/')) %>%
  spTransform(ref)
dynamic_fishing_20_fathom_contour = readOGR(paste0(gis_dir, '/dynamic_fishing_20_fathom_contour/')) %>%
  spTransform(ref)

# create id column for fishing zones
tmp = paste0(dynamic_fishing_grid@data$Grid_Index,dynamic_fishing_grid@data$GRIDSUBARE)
dynamic_fishing_grid@data$ID = gsub(pattern = 'NA', replacement = '', x = tmp)

# read habitat data
critical_habitat_zone = readOGR(paste0(gis_dir, '/critical_habitat_zone/')) %>%
  spTransform(ref)
critical_habitat_grid = readOGR(paste0(gis_dir, '/critical_habitat_grid/')) %>%
  spTransform(ref)

# # test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('static_fishing_zone',
#                       'static_shipping_zone',
#                       'dynamic_fishing_zone',
#                       'dynamic_fishing_grid',
#                       'dynamic_shipping_zone',
#                       'dynamic_fishing_10_fathom_contour',
#                       'dynamic_fishing_20_fathom_contour',
#                       'critical_habitat_zone',
#                       'critical_habitat_grid'
#     )) %>%
#   addPolylines(data = static_shipping_zone, color = 'blue', 
#                group = 'static_shipping_zone',weight = 2) %>%
#   addPolygons(data = dynamic_shipping_zone, color = 'orange', 
#               group = 'dynamic_shipping_zone',weight = 2) %>%
#   addPolygons(data = static_fishing_zone, color = 'red', 
#               group = 'static_fishing_zone',weight = 2) %>%
#   addPolygons(data = dynamic_fishing_zone, color = 'darkgreen', 
#               group = 'dynamic_fishing_zone', weight = 2) %>%
#   addPolygons(data = dynamic_fishing_grid, color = 'lightgreen',
#                group = 'dynamic_fishing_grid', weight = 1, popup = ~paste0(ID)) %>%
#   addPolylines(data = dynamic_fishing_10_fathom_contour, color = 'black',
#               group = 'dynamic_fishing_10_fathom_contour', weight = 1) %>%
#   addPolylines(data = dynamic_fishing_20_fathom_contour, color = 'grey',
#               group = 'dynamic_fishing_20_fathom_contour', weight = 1) %>%
#   addPolygons(data = critical_habitat_zone, color = 'purple', 
#               group = 'critical_habitat_zone', weight = 2) %>%
#   addPolygons(data = critical_habitat_grid, color = 'pink',
#                group = 'critical_habitat_grid', weight = 1, popup = ~paste0(Grid_Index))

# save
save(static_shipping_zone,
     dynamic_shipping_zone,
     static_fishing_zone,
     dynamic_fishing_grid,
     dynamic_fishing_zone,
     dynamic_fishing_10_fathom_contour,
     dynamic_fishing_20_fathom_contour,
     critical_habitat_zone,
     critical_habitat_grid,
     file = paste0(output_dir, 'gis.rda'))
