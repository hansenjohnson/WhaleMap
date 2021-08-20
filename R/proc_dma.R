## proc_dma ##
# process US dynamic management area (DMA) data

# input -------------------------------------------------------------------

# input files
ifile = 'data/raw/dma/xmlgenDMA.pl'
ofile = 'data/processed/dma.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(xml2))
suppressPackageStartupMessages(library(sp))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(lubridate))

# common projection
ref = "+proj=longlat +init=epsg:3857"

# process raw sas ---------------------------------------------------------

# read in active DMA data
dmas = xml_find_all(read_xml(ifile), ".//dma")
  
if(length(dmas)>0){
  
  # extract coordinates in a list of polygons
  DMA = vector('list',length = length(dmas))
  for(ii in 1:length(dmas)){
    
    # extract data
    tmp = dmas[[ii]]
    ID = xml_attr(tmp,attr = 'id')
    lat = xml_attr(xml_find_all(tmp, ".//waypoint"),attr = 'lat') %>% as.numeric()
    lon = xml_attr(xml_find_all(tmp, ".//waypoint"),attr = 'lon') %>% as.numeric()
    
    # generate sp polygon
    ply = Polygon(coords = cbind(lon,lat), hole = F)
    DMA[[ii]] = Polygons(list(ply), ID)
  }
  
  # convert to spatial polygons
  splys = SpatialPolygons(Srl = DMA, proj4string = CRS(ref))
  
  # extract polygon metadata and name rows by id
  md = data.frame(
    name = xml_attr(dmas,attr = 'name'),
    triggertype = xml_attr(dmas,attr = 'triggertype'),
    expiration = paste0(xml_attr(dmas,attr = 'expdate'), ' UTC')
  ) 
  rownames(md) = xml_attr(dmas, attr = 'id')
  
  # fix trigger type
  md$triggertype = as.character(md$triggertype)
  md$triggertype[md$triggertype == 'v'] = 'Visual'
  md$triggertype[md$triggertype == 'a'] = 'Acoustic'
  
  # check expiration times
  e_dates = as.Date(as.POSIXct(md$expiration, tz = 'UTC'))
  if(TRUE %in% c(e_dates<Sys.Date())){
    warning("Expired DMA detected!")
  }
  
  # convert to spatial polygon data frame
  dma = SpatialPolygonsDataFrame(Sr = splys, data = md, match.ID = TRUE)
  
} else {
  
  # blank DMA file
  dma = data.frame()
}

# save
save(dma, file = ofile)

# test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('dma')
#     ) %>%
#   addPolygons(data = dma, color = 'orange', popup = ~paste0(name),
#                group = 'dma',weight = 2)
