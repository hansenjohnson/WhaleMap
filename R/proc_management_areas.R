# proc_restricted #
# process restricted areas

# input -------------------------------------------------------------------

# input directory
gis_dir = 'data/raw/gis/'

# output directory
output_dir = 'data/processed/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))

# define data paths
tc_lane_dir = paste0(gis_dir,'dynamic_shipping/')
# tc_zone_dir = paste0(gis_dir,'static_vessel/')
tc_zone_file = paste0(gis_dir,'static_vessel/2019_static_vessel_slowdown.csv')
forage_areas_dir = paste0(gis_dir,'dynamic_fishing/')
static_zone_file = paste0(gis_dir,'static_fishing/2019_static_fishing_closure.csv')

# process -----------------------------------------------------------------

# read in data
tc_lanes = readOGR(tc_lane_dir)
# tc_zone = readOGR(tc_zone_dir)
forage_areas = readOGR(forage_areas_dir)

# subset foraging areas
forage_areas = forage_areas[forage_areas@data$LINKID %in% c(3,4,7,13),]

# process static zone
static_zone = read.csv(static_zone_file)
tc_zone = read.csv(tc_zone_file)

# test with leaflet
# library(leaflet)
# leaflet() %>%
# addTiles() %>%
# addPolygons(data = forage_areas,weight = .5,popup = ~paste0(LINKID))
# addPolygons(data = tc_lanes,weight = .5) 
# addPolygons(data = static_zone,lng = ~lon, lat=~lat, weight = .5, popup = 'Speed reduction zone')
# addPolygons(data = tc_zone,weight = .5, popup = ~paste0(Type)) %>%
# addPolygons(data = forage_areas,weight = .5,popup = ~paste0(LINKID))

# save
save(tc_lanes, tc_zone, static_zone,forage_areas, file = paste0(output_dir, 'management_areas.rda'))
