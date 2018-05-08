# proc_restricted #
# process restricted areas

# input -------------------------------------------------------------------

# input directory
gis_dir = 'data/raw/2018_whalemapdata/GIS_Data/'

# output directory
output_dir = 'data/processed/'

# setup -------------------------------------------------------------------

# libraries
library(rgdal)

# define data paths
tc_lane_dir = paste0(gis_dir,'TCLanes/')
tc_zone_dir = paste0(gis_dir,'SpeedReductionZone/')
static_zone_dir = paste0(gis_dir,'StaticZone/')

# process -----------------------------------------------------------------

# # unzip files
# unzip(zipfile = paste0(gis_dir,'TCLanes.zip'), exdir = tc_lane_dir)
# unzip(zipfile = paste0(gis_dir,'SpeedReductionZone.zip'), exdir = tc_zone_dir)
# unzip(zipfile = paste0(gis_dir,'StaticZone.zip'), exdir = static_zone_dir)

# read in data
tc_lanes = readOGR(tc_lane_dir)
tc_zone = readOGR(tc_zone_dir)
static_zone = readOGR(static_zone_dir)

# # test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addPolygons(data = tc_lanes,weight = .5, popup = ~paste0(Type)) %>%
#   addPolygons(data = static_zone,weight = .5, popup = 'Speed reduction zone') %>%
#   addPolygons(data = tc_zones,weight = .5, popup = ~paste0(Type))

# save
save(tc_lanes, tc_zone, static_zone, file = paste0(output_dir, 'management_areas.rda'))
