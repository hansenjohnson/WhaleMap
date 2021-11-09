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
dfo_zone = readOGR('data/raw/2021_whalemapdata/GIS_data/2021_DFO_Management Measures/') %>%
  spTransform(ref)
dfo_zone = dfo_zone[dfo_zone@data$AreaName != 'Critical Habitat',]
dfo_zone@data$ID = c(
  '<b>DFO fisheries management area</b><br>Bay of Fundy<br>Active year round',
  '<b>DFO fisheries management area</b><br>Gulf of St Lawrence<br>Active until 15 Nov')

# read critical habitat zone
critical_habitat_zone = readOGR('data/raw/2021_whalemapdata/GIS_data/critical_habitat_areas/') %>%
  spTransform(ref)

# read DFO lines
dfo_10f = readOGR('data/raw/2021_whalemapdata/GIS_data/2021_DFO_10 and 20 fathom lines/', layer = 'Fathom_10') %>%
  spTransform(ref)
dfo_20f = readOGR('data/raw/2021_whalemapdata/GIS_data/2021_DFO_10 and 20 fathom lines/', layer = 'Fathom_20') %>%
  spTransform(ref)

# read management grid
full_grid = readOGR('data/raw/2021_whalemapdata/GIS_data/Full_ATL_grids-2021/') %>%
  spTransform(ref)
full_grid@data$Grid_Index = full_grid@data$GridName
full_grid@data$GridName = NULL

# crop to >40 lat

# read US lobster zones
us_lobster0 = readOGR('data/raw/gis/Lobster_Management_Areas/') %>%
  spTransform(ref)

# simplify
us_lobster = gSimplify(us_lobster0, tol=0.01, topologyPreserve=TRUE)
us_lobster = SpatialPolygonsDataFrame(us_lobster, data=us_lobster0@data)

# process US ALWTRP

# read data
z_gsc = readOGR('data/raw/gis/alwtp/Great_South_Channel_Restricted_Trap-Pot_Area/') %>%
  spTransform(ref)
z_gsc@data = data.frame(
  ID = 'Great South Channel Restricted Trap-Pot Area',
  ACTIVE = '01 Apr - 01 Jun')

z_lma = readOGR('data/raw/gis/alwtp/LMA1_Restricted_Area/') %>%
  spTransform(ref)
z_lma@data = data.frame(
  ID = 'LMA 1 Restricted Area',
  ACTIVE = '01 Oct - 01 Jan')

z_mass = readOGR('data/raw/gis/alwtp/Mass_Restricted_Area_State_Expansion/') %>%
  spTransform(ref)
z_mass@data = data.frame(
  ID = 'Massachusetts Restricted Area',
  ACTIVE = '01 Feb - 01 Apr')

z_soi = readOGR('data/raw/gis/alwtp/South_Island_Restricted_Area/') %>%
  spTransform(ref)
z_soi@data = data.frame(
  ID = 'South Island Restricted Area',
  ACTIVE = '01 Feb - 01 Apr')

# combine
alwtrp = rbind(z_gsc, z_lma, z_mass, z_soi)

# test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('tc_zone',
#                       'dfo_zone',
#                       'dfo_10f',
#                       'dfo_20f',
#                       'tc_ra',
#                       'critical_habitat_zone',
#                       'us_lobster')
#     ) %>%
#   addPolygons(data = tc_zone, color = 'blue', popup = ~paste0(ID),
#                group = 'tc_zone',weight = 2) %>%
#   addPolygons(data = dfo_zone, color = 'orange', popup = ~paste0(ID),
#               group = 'dfo_zone',weight = 2) %>%
#   addPolylines(data = dfo_10f, color = 'black',
#               group = 'dfo_10f',weight = 2) %>%
#   addPolylines(data = dfo_20f, color = 'grey',
#               group = 'dfo_20f',weight = 2) %>%
#   addPolygons(data = tc_ra, color = 'grey',
#               group = 'tc_ra',weight = 2) %>%
#   addPolygons(data = us_lobster, color = 'red', popup = ~paste0(COMMNAME),
#               group = 'us_lobster',weight = 2) %>%
#   addPolygons(data = critical_habitat_zone, color = 'darkgreen',
#               group = 'critical_habitat_zone', weight = 2)

# save
save(tc_zone,
     dfo_zone,
     dfo_10f,
     dfo_20f,
     critical_habitat_zone,
     full_grid,
     tc_ra,
     us_lobster,
     alwtrp,
     file = ofile)
