# static map

# setup -------------------------------------------------------------------

# required libraries
library(leaflet)
library(rgdal)
library(htmltools)
library(htmlwidgets)
library(maptools)
library(lubridate)
library(oce)
library(leaflet.extras)

# definitions -------------------------------------------------------------

# time period to show (days)
lag = 30

# output path
fout = '../server_index/whale_map.html'

# define score color palette
obs_levs = c('detected', 'possibly detected', 'sighted')
obs_pal = c('red', 'yellow', 'darkslategray')
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

# map polygons
poly = readRDS('data/processed/map_polygons.rds')

# tracklines
tracks = readRDS('data/processed/tracks.rds')

# latest dcs positions
latest = readRDS('data/processed/dcs_live_latest_position.rds')

# sightings / detections
obs = readRDS('data/processed/observations.rds')

# subset data -------------------------------------------------------------

# observations
Obs = obs[obs$date >= Sys.Date()-lag,]; rm(obs)

# select species
spp = Obs[Obs$species == 'right',]

# tracklines
Tracks = tracks[tracks$date >= Sys.Date()-lag,]; rm(tracks)

# only possible
pos = droplevels(spp[spp$score=='possibly detected',])

# only definite
det = droplevels(spp[spp$score!='possibly detected',])

# basemap -----------------------------------------------------------------

# start basemap
map <- leaflet(spp) %>% 
  
  # add ocean basemap
  addProviderTiles(providers$Esri.OceanBasemap) %>%
  
  # add place names layer
  addProviderTiles(providers$Hydda.RoadsAndLabels, group = 'names') %>%
  
  # center on observations
  fitBounds(~max(lon, na.rm = T), 
            ~min(lat, na.rm = T), 
            ~min(lon, na.rm = T), 
            ~max(lat, na.rm = T)) %>%
  
  # layer control
  addLayersControl(overlayGroups = c('names',
                                     'tracks',
                                     'latest', 
                                     'possible',
                                     'detected',
                                     'legend'),
                   options = layersControlOptions(collapsed = TRUE), position = 'topright') %>%

  # hide groups
  hideGroup('names') %>%
  
  # add legend
  addLegend(position = "bottomright",
            group = 'legend',
            pal = pal, values = obs_levs, 
            title = 'Score') %>%
  
  # add graticules
  addWMSTiles(
    'https://gis.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer',
    layers = c('1', '2', '3'),
    options = WMSTileOptions(format = "image/png8", transparent = TRUE),
    attribution = "NOAA", group = 'graticules') %>%
  
  # add extra map features
  addScaleBar(position = 'bottomleft')%>%
  addFullscreenControl(pseudoFullscreen = TRUE) %>%
  addMeasure(
    primaryLengthUnit = "kilometers",
    secondaryLengthUnit = 'miles', 
    primaryAreaUnit = "hectares",
    secondaryAreaUnit="acres", 
    activeColor = "darkslategray",
    completedColor = "darkslategray",
    position = 'bottomleft')

# plot polygons -----------------------------------------------------------

# set up polyline plotting
poly.df <- split(poly, poly$name)

# add lines
names(poly.df) %>%
  purrr::walk( function(df) {
    map <<- map %>%
      addPolygons(data=poly.df[[df]], group = 'poly',
                  fill = T, fillOpacity = 0.05, stroke = T,
                  dashArray = c(5,5), options = pathOptions(clickable = F),
                  # label = ~paste0(name),
                  # popup = ~paste0(name),
                  lng=~lon, lat=~lat, weight = 1, color = 'grey', fillColor = 'grey')
  })


# add tracks --------------------------------------------------------------

# set up track plotting
tracks.df <- split(Tracks, Tracks$id)

# add lines
names(tracks.df) %>%
  purrr::walk( function(df) {
    map <<- map %>%
      addPolylines(data=tracks.df[[df]], group = 'tracks',
                   lng=~lon, lat=~lat, weight = 2,
                   popup = paste0('Track ID: ', unique(tracks.df[[df]]$id)),
                   smoothFactor = 3, color = getColor(tracks.df[[df]]))
  })

# add platform icons ------------------------------------------------------

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
                                     as.character(time), ' UTC'), group = 'latest') %>%

# add possible detections -------------------------------------------------

# possible detections
addCircleMarkers(data = pos, ~lon, ~lat, group = 'possible',
                 radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                 fillColor = pal(pos$score),
                 popup = ~paste(sep = "<br/>" ,
                                strong("Sighting/Detection Details:"),
                                paste0("Species: ", species),
                                "Score: possible",
                                paste0("Platform: ", platform),
                                paste0("Name: ", name),
                                paste0('Date: ', as.character(date)),
                                paste0('Position: ',
                                       as.character(lat), ', ', as.character(lon))),
                 label = ~paste0(as.character(date), ': ', species,' whale ', score, ' by ', name),
                 options = markerOptions(removeOutsideVisibleBounds=T)) %>%
                 
# add definite detections/sightings ---------------------------------------

addCircleMarkers(data = det, ~lon, ~lat, group = 'detected',
                 radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                 fillColor = pal(det$score),
                 popup = ~paste(sep = "<br/>" ,
                                strong("Sighting/Detection Details:"),
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

