# proc_gis #
# process GIS data (management areas, critical habitats, etc.)

# input -------------------------------------------------------------------

# output file
ofile = 'data/processed/gis.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(tidyverse))

# common projection
ref = '+proj=longlat +datum=WGS84'

# process -----------------------------------------------------------------

# read TC shipping zone
tc_zone = st_read('data/raw/gis/can/2021_TC_Management Measures/') %>%
  st_transform(ref)

# read TC restricted area
tc_ra = st_read('data/raw/gis/can/2021_TC_NARW_Restricted Area/') %>%
  st_transform(ref)
tc_ra = tc_ra %>% filter(ID == 'SHEDIAC_RA')

# read fishing data from DFO
dfo_zone = st_read('data/raw/gis/can/2021_DFO_Management Measures/') %>%
  st_transform(ref)
dfo_zone = dfo_zone %>% filter(AreaName != 'Critical Habitat')
dfo_zone$ID = c(
  '<b>DFO fisheries management area</b><br>Bay of Fundy<br>Active year round',
  '<b>DFO fisheries management area</b><br>Gulf of St Lawrence<br>Active until 15 Nov')

# read critical habitat zone
critical_habitat_zone = st_read('data/raw/gis/can/critical_habitat_areas/') %>%
  st_transform(ref)

# read DFO lines
dfo_10f = st_read('data/raw/gis/can/2021_DFO_10 and 20 fathom lines/', layer = 'Fathom_10') %>%
  st_transform(ref)
dfo_20f = st_read('data/raw/gis/can/2021_DFO_10 and 20 fathom lines/', layer = 'Fathom_20') %>%
  st_transform(ref)

# # read management grid
# full_grid = readOGR('data/raw/gis/can/Full_ATL_grids-2021/') %>%
#   st_transform(ref)
# full_grid@data$Grid_Index = full_grid@data$GridName
# full_grid@data$GridName = NULL

# crop to >40 lat

# read US lobster zones
us_lobster0 = st_read('data/raw/gis/Lobster_Management_Areas/') %>%
  st_transform(ref)

# simplify
us_lobster = st_simplify(us_lobster0, dTolerance = 0.01, preserveTopology = TRUE)

# process US ALWTRP

# read data
z_gsc = st_read('data/raw/gis/alwtp/Great_South_Channel_Restricted_Trap-Pot_Area/') %>%
  st_transform(ref)
z_gsc$ID = 'Great South Channel Restricted Trap-Pot Area'
z_gsc$ACTIVE = '01 Apr - 30 Jun'
z_gsc = z_gsc %>% select(ID,ACTIVE,geometry)

z_lma = st_read('data/raw/gis/alwtp/LMA 1 RA ed/') %>%
  st_transform(ref)
z_lma$ID = 'LMA 1 Restricted Area'
z_lma$ACTIVE = '01 Oct - 31 Jan'
z_lma = z_lma %>% select(ID,ACTIVE,geometry)

z_mass0 = st_read('data/raw/gis/alwtp/Mass_Restricted_Area_State_Expansion/') %>%
  st_transform(ref)
z_mass = st_simplify(z_mass0, dTolerance = 0.01, preserveTopology = TRUE)
z_mass$ID = 'Massachusetts Restricted Area'
z_mass$ACTIVE = '01 Feb - 30 Apr'
z_mass = z_mass %>% select(ID,ACTIVE,geometry)

z_soi = st_read('data/raw/gis/alwtp/South_Island_Restricted_Area/') %>%
  st_transform(ref)
z_soi$ID = 'South Island Restricted Area'
z_soi$ACTIVE = '01 Feb - 30 Apr'
z_soi = z_soi %>% select(ID,ACTIVE,geometry)

z_ccb = st_read('data/raw/gis/alwtp/Cape_Cod_Bay_Restricted_Area/') %>%
  st_transform(ref)
z_ccb$ID = 'Cape Cod Bay Restricted Area'
z_ccb$ACTIVE = '01 Jan - 15 Apr'
z_ccb = z_ccb %>% select(ID,ACTIVE,geometry)

z_seraN = st_read('data/raw/gis/alwtp/Southeast_US_Restricted_Area/north/') %>%
  st_transform(ref)
z_seraN$ID = 'Southeast US Restricted Area (North)'
z_seraN$ACTIVE = '15 Nov - 15 Apr'
z_seraN = z_seraN %>% select(ID,ACTIVE,geometry)

z_seraS = st_read('data/raw/gis/alwtp/Southeast_US_Restricted_Area/south/') %>%
  st_transform(ref)
z_seraS$ID = 'Southeast US Restricted Area (South)'
z_seraS$ACTIVE = '01 Dec - 31 Mar'
z_seraS = z_seraS %>% select(ID,ACTIVE,geometry)

# combine
alwtrp = rbind(z_gsc, z_lma, z_mass, z_soi, z_ccb, z_seraN, z_seraS)

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
     # full_grid,
     tc_ra,
     us_lobster,
     alwtrp,
     file = ofile)
