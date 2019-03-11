library(leaflet)
library(leaflet.extras)

map = leaflet() %>% 
  addTiles() %>% setView(lng = -65, lat = 45, zoom = 5) %>%
  addMarkers(lng = -65, lat = 45, group = 'ui') %>%
  addDrawToolbar(targetGroup = 'ui',
                 position = c("topleft"),
                 polylineOptions = F,
                 polygonOptions = F,
                 circleOptions = F,
                 rectangleOptions = F,
                 markerOptions = drawMarkerOptions(repeatMode = T), 
                 editOptions = editToolbarOptions(),
                 singleFeature = F
  )
