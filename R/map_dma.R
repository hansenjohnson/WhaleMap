## map_dma ##
# process US dynamic management area (DMA) data

# input -------------------------------------------------------------------

ofile = 'data/processed/dma.rda'

# setup -------------------------------------------------------------------

library(httr)
library(sf)

# process -----------------------------------------------------------------

# get url dma as follows:
# 1) go to query page: https://services2.arcgis.com/C8EMgrsFcRFL6LrL/arcgis/rest/services/NEFSC_Dynamic_Management_Areas/FeatureServer/0/query/?where=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=&returnGeometry=true&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=html&token=
# 2) set "Where: 1=1" and "Out Fields: *" and "Format: GEOJSON"
# 3) click "Query (GET)" and paste subsequent URL below
url_dma = 'https://services2.arcgis.com/C8EMgrsFcRFL6LrL/arcgis/rest/services/NEFSC_Dynamic_Management_Areas/FeatureServer/0/query/?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# read in dma data
dma <- st_read(url_dma, quiet = TRUE)

if(length(dma)>0){
  
  # check expiration times
  e_dates = as.Date(as.POSIXct(as.character(dma$EXPDATE), format = "%d-%b-%Y %H:%M:%S", tz = 'UTC'))
  if(TRUE %in% c(e_dates<Sys.Date())){
    warning("Expired DMA detected!")
  }
  
} else {
  
  # blank DMA file
  dma = data.frame()
}

# save
save(dma, file = ofile)

# # test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('dma')
#   ) %>%
#   addPolygons(data = dma, color = 'orange', 
#               popup = ~paste(sep = "<br/>" ,
#                              "US Slow Zone",
#                              paste0(NAME),
#                              # paste0("Type: ", triggertype),
#                              paste0("Expires: ", EXPDATE)),
#               group = 'dma',weight = 2)
