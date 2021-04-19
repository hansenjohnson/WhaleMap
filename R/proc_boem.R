# proc_boem #
# process energy development areas from BOEM

# input -------------------------------------------------------------------

# output directory
ofile = 'data/processed/boem.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(sf))

## Query steps ##
# 1. Go to specific layer on ArcGIS rest api: https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer
# 2. Click 'query'
# 3. Add the following fields:
# Where: 1=1
# Out Fields: *
# Format: GEOJSON
# 4. Click 'query' and paste url below

# wind lease areas 
query1 = 'https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# wind MHK leases and planning areas 
query2 = 'https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer/1/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# wind planning areas
query3 = 'https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer/2/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# process -----------------------------------------------------------------

# read
q1 = st_read(query1, quiet = TRUE) 
q2 = st_read(query2, quiet = TRUE) 
q3 = st_read(query3, quiet = TRUE) 

# combine
df = rbind(q1[,c('INFO', 'geometry')], 
           q2[,c('INFO', 'geometry')], 
           q3[,c('INFO', 'geometry')])

# crop to east coast
df = suppressMessages(
  suppressWarnings(
    st_crop(x = df, y = c(xmin = -82, xmax = -67, ymin = 26, ymax = 60))
  )
)

# calculate common border
zones = unique(df$INFO)
BOEM = vector('list', length = length(zones))
for(ii in seq_along(zones)){
  tmp = suppressMessages(
    suppressWarnings(
      st_as_sf(st_union(st_buffer(df[df$INFO == zones[ii],], dist = 0.0001)))
    )
  )
  tmp$ID = zones[ii]
  BOEM[[ii]] = tmp
}

# flatten list
boem = bind_rows(BOEM)

# # plot to test
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addPolygons(data = df, color = 'red', popup = ~paste0(INFO), weight = 2) %>%
#   addPolygons(data = boem, color = 'blue', popup = ~paste0(ID), weight = 2)

# save
save(boem, file = ofile)
