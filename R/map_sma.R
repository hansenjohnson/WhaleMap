## map_sma ##
# process US seasonal management area (SMA) data

# input -------------------------------------------------------------------

ofile = 'data/processed/sma.rda'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(sf))

# process -----------------------------------------------------------------

# get url as follows:
# 1) go to service page: https://services2.arcgis.com/C8EMgrsFcRFL6LrL/arcgis/rest/services/Seasonal_Management_Areas/FeatureServer/3
# 2) click on 'query' at the bottom to navigate to query page
# 2) set "Where: 1=1" and "Out Fields: *" and "Format: GEOJSON"
# 3) click "Query (GET)" and paste subsequent URL below
url_sma = 'https://services2.arcgis.com/C8EMgrsFcRFL6LrL/arcgis/rest/services/Seasonal_Management_Areas/FeatureServer/3/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnCentroid=false&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# read in dma data
sma <- st_read(url_sma, quiet = TRUE)

# today's date
dt = Sys.Date()
yr = year(dt)

# make sure month/day fields are integers
st_mo  = as.integer(sma$st_mo)
st_day = as.integer(sma$st_day)
end_mo  = as.integer(sma$end_mo)
end_day = as.integer(sma$end_day)

# encode month/day as MMDD numbers for year-independent comparison
st_md    = st_mo * 100 + st_day
end_md   = end_mo * 100 + end_day
today_md = month(dt) * 100 + day(dt)

# zones whose season crosses Dec 31 (e.g., Nov 1 - Apr 30)
wraps = st_md > end_md

# for wrapping zones, if today is before the start month/day,
# we're in the Jan-to-end part of a season that began last year
st_yr  = ifelse(wraps & today_md < st_md, yr - 1, yr)
end_yr = ifelse(wraps, st_yr + 1, st_yr)

# define start and end dates
sma$st_date  = make_date(st_yr,  st_mo,  st_day)
sma$end_date = make_date(end_yr, end_mo, end_day)

# determine which zones are active
sma$active = dt >= sma$st_date & dt <= sma$end_date

# define start/end date labels
sma$STARTDATE = paste0(month(sma$st_mo, label = T),' ', sma$st_day)
sma$ENDDATE = paste0(month(sma$end_mo, label = T),' ', sma$end_day)

# define name
sma$NAME = sma$zone_name

# select only active
sma <- sma[sma$active == TRUE,]

# fix projection
st_crs(sma) <- st_crs('+proj=longlat +datum=WGS84')

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
#                              paste0("Active: ",STARTDATE, ' - ', ENDDATE)),
#               group = 'sma',weight = 2)
