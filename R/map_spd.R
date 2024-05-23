## map_spd ##
# map proposed right whale speed rule

# input -------------------------------------------------------------------

ofile = 'data/processed/spd.rda'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(lubridate))

# process -----------------------------------------------------------------

# get url as follows:
# 1) go to service page: https://services2.arcgis.com/C8EMgrsFcRFL6LrL/ArcGIS/rest/services/Proposed_Right_Whale_Seasonal_Speed_Zones_Original/FeatureServer/8
# 2) click on 'query' at the bottom to navigate to query page
# 2) set "Where: 1=1" and "Out Fields: *" and "Format: GEOJSON"
# 3) click "Query (GET)" and paste subsequent URL below
url_spd = 'https://services2.arcgis.com/C8EMgrsFcRFL6LrL/ArcGIS/rest/services/Proposed_Right_Whale_Seasonal_Speed_Zones_Original/FeatureServer/8/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# read in dma data
spd <- st_read(url_spd, quiet = TRUE)

# fix dates
spd = spd %>%
  mutate(
    NAME = ssz,
    STARTDATE = paste0(month(st_mo, label = TRUE, abbr = TRUE),' ',st_day),
    ENDDATE = paste0(month(end_mo, label = TRUE, abbr = TRUE),' ',end_day)
  )

# fix projection
st_crs(spd) <- st_crs('+proj=longlat +datum=WGS84')

# save
save(spd, file = ofile)

# test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('spd')
#   ) %>%
#   addPolygons(data = spd, color = 'purple',
#               popup = ~paste(sep = "<br/>" ,
#                              "US Proposed Speed Rule",
#                              paste0(ssz),
#                              paste0("Active: ",STARTDATE, ' - ', ENDDATE)),
#               group = 'spd',weight = 2)


