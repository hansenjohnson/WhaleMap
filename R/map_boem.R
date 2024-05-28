# proc_boem #
# process energy development areas from BOEM

# input -------------------------------------------------------------------

# output directory
ofile = 'data/processed/boem.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(tidyverse))

## Query steps ##
# 1. Go to specific layer on ArcGIS rest api: https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer
# 2. Click 'query'
# 3. Add the following fields:
# Where: 1=1
# Format: GEOJSON
# 4. Click 'query' and paste url below

# wind lease areas 
query1 = 'https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Wind_Lease_Boundaries__BOEM_/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# wind planning areas 
query2 = 'https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Wind_Planning_Area_Boundaries__BOEM_/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# process -----------------------------------------------------------------

# read
wind_lease = st_read(query1, quiet = TRUE) %>%
  filter(!st_is_empty(geometry)) %>%
  transmute(info = LEASE_NUMBER_COMPANY, geometry) %>%
  group_by(info) %>%
  mutate(max_x = max(data.frame(st_coordinates(geometry))$X,na.rm=T)) %>%
  ungroup() %>%
  filter(max_x >= -85) %>%
  select(-max_x)

wind_planning = st_read(query2, quiet = TRUE) %>%
  filter(!st_is_empty(geometry)) %>%
  transmute(info = PROTRACTION_NUMBER, geometry) %>%
  rownames_to_column() %>%
  group_by(rowname) %>%
  mutate(max_x = max(data.frame(st_coordinates(geometry))$X, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(max_x >= -85) %>%
  select(-max_x,-rowname)

# # plot to test
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addPolygons(data = wind_lease_areas, color = 'red', popup = ~paste0(info), weight = 2) %>%
#   addPolygons(data = wind_planning_areas, color = 'blue', popup = ~paste0(info), weight = 2)

# save
save(wind_planning, wind_lease, file = ofile)
