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
lag = 14
start_date = Sys.Date()-lag

# output path
fout = '../server_index/whale_map.html'

# define score color palette
obs_levs = c('detected', 'possibly detected', 'sighted', 'possibly sighted')
obs_pal = c('red', 'yellow', 'darkslategray', 'grey')
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

# tracklines
tracks = readRDS('data/processed/tracks.rds')

# latest dcs positions
latest = readRDS('data/processed/dcs_live_latest_position.rds')

# sightings / detections
obs = readRDS('data/processed/observations.rds')

# subset data -------------------------------------------------------------

# tracklines
Tracks = tracks[tracks$date >= start_date,]; rm(tracks)

# observations
Obs = obs[obs$date >= start_date,]; rm(obs)

# select species
spp = Obs[Obs$species == 'right',]

# # new category for possible sightings
# spp$score = as.character(spp$score)
# spp$score[spp$platform == 'opportunistic'] = 'possibly sighted'
# spp$score = as.factor(spp$score)

# only possible detections
pos = droplevels(spp[spp$score %in% c('possibly detected', 'possibly sighted'),])

# only definite
det = droplevels(spp[!spp$score %in% c('possibly detected', 'possibly sighted'),])

# basemap -----------------------------------------------------------------

# start basemap
map <- leaflet(spp) %>% 
  
  # add ocean basemap
  addProviderTiles(providers$Esri.OceanBasemap) %>%
  
  # add place names layer
  addProviderTiles(providers$Hydda.RoadsAndLabels, group = 'Place names') %>%
  
  # center on observations
  fitBounds(~max(lon, na.rm = T), 
            ~min(lat, na.rm = T), 
            ~min(lon, na.rm = T), 
            ~max(lat, na.rm = T)) %>%
  
  # title and last updated message
  addControl(position = "topright", 
             paste0(
               '<div align="center">',
               '<strong>Right Whale Surveys</strong>','<br>',
               '<small>Last updated: ', 
               format(Sys.time(), '%b-%d at %H:%M', tz = 'UTC', usetz = T), 
               '</small>','<br>',
               '<small>Data from: ', 
               format(start_date, '%b-%d'), ' to ', 
               format(Sys.Date(), '%b-%d'), '</small>',
               '</div>')) %>%
  
  # layer control
  addLayersControl(overlayGroups = c('Place names',
                                     'Protected areas',
                                     'Shipping lanes',
                                     'Graticules',
                                     'Survey tracks',
                                     'Latest robot positions', 
                                     'Possible detections/sightings',
                                     'Definite detections/sightings'),
                   options = layersControlOptions(collapsed = TRUE), position = 'topright') %>%
  
  # hide groups
  hideGroup('Place names') %>%
  
  # add graticules
  addWMSTiles(
    'https://gis.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer',
    layers = c('1', '2', '3'),
    options = WMSTileOptions(format = "image/png8", transparent = TRUE),
    attribution = NULL, group = 'Graticules') %>%
  
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
            values = obs_levs,
            title = 'Score')

# plot polygons -----------------------------------------------------------


# add mpas
map <- map %>%
  addPolygons(data=mpa, group = 'Protected areas',
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 3,
              dashArray = c(5,5), options = pathOptions(clickable = F),
              lng=~lon, lat=~lat, weight = 1, color = 'grey', fillColor = 'grey')

# plot shipping lanes

map <- map %>%
  addPolylines(tss_lines$lon, tss_lines$lat,
               weight = .5,
               color = 'red',
               smoothFactor = 3,
               options = pathOptions(clickable = F),
               group = 'Shipping lanes') %>%
  addPolygons(tss_polygons$lon, tss_polygons$lat,
              weight = .5,
              color = 'red',
              fillColor = 'red',
              smoothFactor = 3,
              options = pathOptions(clickable = F),
              group = 'Shipping lanes')


# add tracks --------------------------------------------------------------

# set up track plotting
tracks.df <- split(Tracks, Tracks$id)

# add lines
names(tracks.df) %>%
  purrr::walk( function(df) {
    map <<- map %>%
      addPolylines(data=tracks.df[[df]], group = 'Survey tracks',
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
                                     as.character(time), ' UTC'), 
                     group = 'Latest robot positions') %>%


# add possible detections/sightings ---------------------------------------

# possible detections
addCircleMarkers(data = pos, ~lon, ~lat, group = 'Possible detections/sightings',
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

addCircleMarkers(data = det, ~lon, ~lat, group = 'Definite detections/sightings',
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

