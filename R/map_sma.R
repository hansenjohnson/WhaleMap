## map_sma ##
# process US dynamic management area (DMA) data

# input -------------------------------------------------------------------

ofile = 'data/processed/sma.rda'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(sf))

# process -----------------------------------------------------------------

# get url as follows:
# 1) go to query page: https://services2.arcgis.com/C8EMgrsFcRFL6LrL/ArcGIS/rest/services/NEFSC_Seasonal_Management_Areas/FeatureServer/0/query
# 2) set "Where: 1=1" and "Out Fields: *" and "Format: GEOJSON"
# 3) click "Query (GET)" and paste subsequent URL below
url_sma = 'https://services2.arcgis.com/C8EMgrsFcRFL6LrL/ArcGIS/rest/services/NEFSC_Seasonal_Management_Areas/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# read in dma data
sma <- st_read(url_sma, quiet = TRUE)

# select only active
sma <- sma %>% filter(INEFFECT == 1)

# save
save(sma, file = ofile)

# # test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('sma')
#   ) %>%
#   addPolygons(data = sma, color = 'purple',
#               popup = ~paste(sep = "<br/>" ,
#                              "US Seasonal Management Area",
#                              paste0(NAME),
#                              # paste0("Type: ", triggertype),
#                              paste0("Expires: ", ENDDATE)),
#               group = 'sma',weight = 2)
