# static map

# setup -------------------------------------------------------------------

# required libraries
library(leaflet, quietly = T, warn.conflicts = F)
suppressMessages(library(rgdal, quietly = T, warn.conflicts = F))
library(htmltools, quietly = T, warn.conflicts = F)
library(htmlwidgets, quietly = T, warn.conflicts = F)
library(maptools, quietly = T, warn.conflicts = F)
library(lubridate, quietly = T, warn.conflicts = F)
library(oce, quietly = T, warn.conflicts = F)
library(leaflet.extras, quietly = T, warn.conflicts = F)

# definitions -------------------------------------------------------------

# time period to show (days)
lag = 14
start_date = Sys.Date()-lag

# output path
fout = '../server_index/whale_map.html'

# define score color palette
obs_levs = c('acoustic', 'visual')
obs_pal = c('red', 'darkslategray')
pal = colorFactor(levels = obs_levs,
                  palette = obs_pal)

# make dcs icons
dcsIcons = iconList(
  slocum = makeIcon("icons/slocum.png", iconWidth = 40, iconHeight = 40),
  wave = makeIcon("icons/wave.png", iconWidth = 35, iconHeight = 30),
  buoy = makeIcon("icons/buoy.png", iconWidth = 50, iconHeight = 40)
)

# define function to determine trackline color
getColor <- function(tracks) {
  if(tracks$platform[1] == 'slocum') {
    "blue"
  } else if(tracks$platform[1] == 'plane') {
    "#8B6914"
  } else if(tracks$platform[1] == 'vessel'){
    "black"
  } else if(tracks$platform[1] == 'wave'){
    "purple"
  } else {
    "darkgrey"
  }
}

# read in data -------------------------------------------------------

# read in map polygons
mpa = readRDS('data/processed/mpa.rds')
load('data/processed/tss.rda')
load('data/processed/management_areas.rda')

# tracklines
tracks = readRDS('data/processed/tracks.rds')

# latest dcs positions
lfile = 'data/processed/dcs_live_latest_position.rds'
if(file.exists(lfile)){
  latest = readRDS(lfile)
}

# sightings / detections
obs = readRDS('data/processed/observations.rds')

# subset data -------------------------------------------------------------

# tracklines
Tracks = tracks[tracks$date >= start_date,]; rm(tracks)
Tracks = Tracks[Tracks$name!='cp_king_air',] # do not plot C&P data

# observations
Obs = obs[obs$date >= start_date,]; rm(obs)

# select species
spp = Obs[Obs$species == 'right',]

# only possible detections
# pos = droplevels(spp[spp$score == 'possibly detected',]) # do not plot possible sightings

# only definite
det = droplevels(spp[!spp$score %in% c('possible acoustic', 'possible visual'),])

# basemap -----------------------------------------------------------------

# start basemap
map <- leaflet() %>%

  # add ocean basemap
  addProviderTiles(providers$Esri.OceanBasemap) %>%

  # add place names layer
  addProviderTiles(providers$Hydda.RoadsAndLabels, group = 'Place names') %>%

  # title and last updated message
  addControl(position = "topright",
             paste0(
               '<div align="center">',
               '<strong>Right Whale Observations</strong>','<br>',
               '<small>Last updated: ',
               format(Sys.time(), '%b-%d at %H:%M', tz = 'UTC', usetz = T),
               '</small>','<br>',
               '<small>Data from: ',
               format(start_date, '%b-%d'), ' to ',
               format(Sys.Date(), '%b-%d'), '</small>',
               '</div>')) %>%

  # layer control
  addLayersControl(overlayGroups = c('Survey tracks',
                                     'Latest robot positions',
                                     'Right whale observations',
                                     'Protected areas',
                                     'Shipping lanes',
                                     'GoSL static speed reduction zone',
                                     'GoSL dynamic speed reduction zones',
                                     'GoSL static fisheries closure',
                                     'Graticules',
                                     'Place names'
                                     ),
                   options = layersControlOptions(collapsed = TRUE), position = 'topright') %>%

  # hide groups
  hideGroup(c('Place names',
              'Survey tracks',
              'Latest robot positions',
              'GoSL static speed reduction zone',
              'GoSL dynamic speed reduction zones',
              'GoSL static fisheries closure')) %>%

  # # add graticules
  # addWMSTiles(
  #   'https://gis.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer',
  #   layers = c('1', '2', '3'),
  #   options = WMSTileOptions(format = "image/png8", transparent = TRUE),
  #   attribution = NULL, group = 'Graticules') %>%

  # use NOAA graticules
  addWMSTiles(
    "https://gis.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer/",
    layers = c("1-degree grid", "5-degree grid"),
    options = WMSTileOptions(format = "image/png8", transparent = TRUE),
    attribution = NULL,group = 'Graticules') %>%

  # add extra map features
  addScaleBar(position = 'bottomleft')%>%
  addFullscreenControl(pseudoFullscreen = F) %>%
  addMeasure(
    primaryLengthUnit = "kilometers",
    secondaryLengthUnit = 'miles',
    primaryAreaUnit = "hectares",
    secondaryAreaUnit="acres",
    activeColor = "darkslategray",
    completedColor = "darkslategray",
    position = 'bottomleft') %>%

  # add legend
  addLegend(position = "bottomright",
            pal = pal,
            values = obs_levs)

# center on observations (if present)
# if(nrow(Tracks)!=0){
#
#   # define an offset (in deg) to buffer bounds around latest observations
#   offset = 0.05
#
#   map <- fitBounds(map = map,
#             max(Tracks$lon, na.rm = T)+offset,
#             min(Tracks$lat, na.rm = T)-offset,
#             min(Tracks$lon, na.rm = T)-offset,
#             max(Tracks$lat, na.rm = T)+offset)
# } else {
#   map <- setView(map = map, lng = -65, lat = 45, zoom = 5)
# }

# center on entire region
map <- setView(map = map, lng = -65, lat = 45, zoom = 5)

# plot polygons -----------------------------------------------------------

# add mpas
map <- map %>%
  addPolygons(data=mpa, group = 'Protected areas',
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(5,5), options = pathOptions(clickable = F),
              lng=~lon, lat=~lat, weight = 1, color = 'darkgreen', fillColor = 'darkgreen')

# plot shipping lanes

map <- map %>%
  addPolylines(tss_lines$lon, tss_lines$lat,
               weight = .5,
               color = 'grey',
               smoothFactor = 0,
               options = pathOptions(clickable = F),
               group = 'Shipping lanes') %>%
  addPolygons(tss_polygons$lon, tss_polygons$lat,
              weight = .5,
              color = 'grey',
              fillColor = 'grey',
              smoothFactor = 0,
              options = pathOptions(clickable = F),
              group = 'Shipping lanes')

# plot static speed reduction zone
map <- map %>%
  addPolygons(data=tc_zone, group = 'GoSL static speed reduction zone',
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(5,5), options = pathOptions(clickable = F),
              weight = .25, color = 'grey', fillColor = 'grey')

# plot dynamic speed reduction zone
map <- map %>%
  addPolygons(data=tc_lanes, group = 'GoSL dynamic speed reduction zones',
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(5,5), options = pathOptions(clickable = F),
              weight = .25, color = 'purple', fillColor = 'purple')

# plot static fisheries closue
map <- map %>%
  addPolygons(data=static_zone, group = 'GoSL static fisheries closure',
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(2,2), options = pathOptions(clickable = F),
              weight = 1, color = 'darkblue', fillColor = 'darkblue')

# add tracks --------------------------------------------------------------

# set up track plotting
tracks.df <- split(Tracks, Tracks$id)

# add lines
names(tracks.df) %>%
  purrr::walk( function(df) {
    map <<- map %>%
      addPolylines(data=tracks.df[[df]], group = 'Survey tracks',
                   lng=~lon, lat=~lat, weight = 2,
                   popup = paste0('Survey completed by: ', unique(tracks.df[[df]]$name)),
                   smoothFactor = 1, color = getColor(tracks.df[[df]]))
  })

# add platform icons ------------------------------------------------------

if(file.exists(lfile)){

  # add icons for latest position of live dcs platforms
  map <- map %>% addMarkers(data = latest, ~lon, ~lat, icon = ~dcsIcons[platform],
                            popup = ~paste(sep = "<br/>",
                                           strong('Latest position'),
                                           paste0('Platform: ', as.character(platform)),
                                           paste0('Name: ', as.character(name)),
                                           paste0('Time: ', as.character(time), ' UTC'),
                                           paste0('Position: ',
                                                  as.character(lat), ', ', as.character(lon))),
                            label = ~paste0('Latest position of ', as.character(name), ': ',
                                            as.character(time), ' UTC'),
                            group = 'Latest robot positions')
}

# add possible detections/sightings ---------------------------------------

# possible detections
# map <- map %>% addCircleMarkers(data = pos, ~lon, ~lat, group = 'Possible detections/sightings',
#                  radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
#                  fillColor = pal(pos$score),
#                  popup = ~paste(sep = "<br/>" ,
#                                 strong("Sighting/Detection Details:"),
#                                 paste0("Species: ", species),
#                                 "Score: possible",
#                                 paste0("Platform: ", platform),
#                                 paste0("Name: ", name),
#                                 paste0('Date: ', as.character(date)),
#                                 paste0('Position: ',
#                                        as.character(lat), ', ', as.character(lon))),
#                  label = ~paste0(as.character(date), ': ', species,' whale ', score, ' by ', name),
#                  options = markerOptions(removeOutsideVisibleBounds=T)) %>%

# add definite detections/sightings ---------------------------------------

map <- map %>% addCircleMarkers(data = det, ~lon, ~lat, group = 'Right whale observations',
                 radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                 fillColor = pal(det$score),
                 popup = ~paste(sep = "<br/>" ,
                                strong("Details:"),
                                paste0("Species: ", species),
                                paste0("Score: ", score),
                                paste0("Number: ", number),
                                paste0("Platform: ", platform),
                                paste0("Name: ", name),
                                paste0('Date: ', as.character(date)),
                                paste0('Position: ',
                                       as.character(lat), ', ', as.character(lon))),
                 label = ~paste0(as.character(date), ': ', species,' whale ', score, ' by ', name),
                 options = markerOptions(removeOutsideVisibleBounds=T))

# save widget -------------------------------------------------------------

saveWidget(widget = map, file = fout, selfcontained = T)
