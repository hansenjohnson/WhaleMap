# proc_gis #
# process GIS data (management areas, critical habitats, etc.)

# input -------------------------------------------------------------------

# output file
ofile = 'data/processed/gis.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(rgeos))

# common projection
ref = "+proj=longlat +init=epsg:3857"

# process -----------------------------------------------------------------

# read TC shipping zone
tc_zone = readOGR('data/raw/2021_whalemapdata/GIS_data/2021_TC_Management Measures/') %>%
  spTransform(ref)

# read TC restricted area
tc_ra = readOGR('data/raw/2021_whalemapdata/GIS_data/2021_TC_NARW_Restricted Area/') %>%
  spTransform(ref)
tc_ra = tc_ra[tc_ra@data$ID == 'SHEDIAC_RA',]

# read fishing data from DFO
dfo_zone = readOGR(paste0(gis_dir, '/2021_DFO_Management Measures/')) %>%
  spTransform(ref)
dfo_zone@data$ID = c(
  '<b>DFO fisheries management area</b><br>Bay of Fundy<br>Active year round',
  '<b>DFO fisheries management area</b><br>Gulf of St Lawrence<br>Active until 15 Nov')

# read critical habitat zone
critical_habitat_zone = readOGR(paste0(gis_dir, '/critical_habitat_areas/')) %>%
  spTransform(ref)

# read management grid
full_grid = readOGR(paste0(gis_dir, '/Full_ATL_grids-2021/')) %>%
  spTransform(ref)

# read US lobster zones
us_lobster0 = readOGR('data/raw/gis/Lobster_Management_Areas/') %>%
  spTransform(ref)

# simplify
us_lobster = gSimplify(us_lobster0, tol=0.01, topologyPreserve=TRUE)
us_lobster = SpatialPolygonsDataFrame(us_lobster, data=us_lobster0@data)

# test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('tc_zone',
#                       'dfo_zone',
#                       'tc_ra',
#                       'critical_habitat_zone',
#                       'us_lobster')
#     ) %>%
#   addPolygons(data = tc_zone, color = 'blue', popup = ~paste0(ID),
#                group = 'tc_zone',weight = 2) %>%
#   addPolygons(data = dfo_zone, color = 'orange', popup = ~paste0(ID),
#               group = 'dfo_zone',weight = 2) %>%
#   addPolygons(data = tc_ra, color = 'grey',
#               group = 'tc_ra',weight = 2) %>%
#   addPolygons(data = us_lobster, color = 'red', popup = ~paste0(COMMNAME),
#               group = 'us_lobster',weight = 2) %>%
#   addPolygons(data = critical_habitat_zone, color = 'darkgreen',
#               group = 'critical_habitat_zone', weight = 2)

# save
save(tc_zone,
     dfo_zone,
     critical_habitat_zone,
     full_grid,
     tc_ra,
     us_lobster,
     file = ofile)
