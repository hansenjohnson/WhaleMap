# static map - biligual version

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
obs_levs = c('Acoustic / acoustique', 'Visual / visuelle')
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

# only definite
det = droplevels(spp[!spp$score %in% c('possible acoustic', 'possible visual'),])

# basemap -----------------------------------------------------------------

# define layer labels
survey_grp = 'Survey tracks / <br> Trajet Suivi'
robot_grp = 'Latest robot positions / <br> position la plus récente des robots'
graticules_grp = 'Graticules / <br> graticules'
rw_grp = 'Right whale observations / <br> Observation des baleines noires'
mpa_grp = 'Protected areas / <br> Zone protégée'
tss_grp = 'Shipping lanes / <br> Couloirs de navigation'
static_speed_grp = 'Static speed reduction zone / <br> Zones de réduction de vitesse statique'
dynamic_speed_grp = 'Dynamic speed reduction zone / <br> Zones de réduction de vitesse dynamique'
static_fish_grp = 'Static fisheries closure / <br> Fermeture statique de la pêche'

# start basemap
map <- leaflet() %>%

  # add ocean basemap
  addProviderTiles(providers$OpenStreetMap.Mapnik) %>%

  # title and last updated message
  addControl(position = "topright",
             paste0(
               '<div align="center">',
               '<strong>Right whale observations / <br> 
               Observation des baleines noires</strong>','<br>',
               '<small>Data from / Données de: ','<br>',
               format(start_date, '%Y-%m-%d'), ' - ',
               format(Sys.Date(), '%Y-%m-%d'), '</small>',
               '</div>')) %>%

  # layer control
  addLayersControl(overlayGroups = c(survey_grp,
                                     robot_grp,
                                     rw_grp,
                                     mpa_grp,
                                     tss_grp,
                                     static_speed_grp,
                                     dynamic_speed_grp,
                                     static_fish_grp,
                                     graticules_grp
                                     ),
                   options = layersControlOptions(collapsed = TRUE), position = 'topright') %>%

  # hide groups
  hideGroup(c(survey_grp,
              graticules_grp,
              static_speed_grp,
              dynamic_speed_grp,
              static_fish_grp)) %>%

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
    attribution = NULL,group = graticules_grp) %>%

  # add extra map features
  addScaleBar(position = 'bottomleft')%>%
  addFullscreenControl(pseudoFullscreen = F) %>%

  # add legend
  addLegend(position = "bottomright",
            pal = pal,
            values = obs_levs)

# center on entire region
map <- setView(map = map, lng = -63, lat = 48, zoom = 5)

# plot polygons -----------------------------------------------------------

# add mpas
map <- map %>%
  addPolygons(data=mpa, group = mpa_grp,
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
               group = tss_grp) %>%
  addPolygons(tss_polygons$lon, tss_polygons$lat,
              weight = .5,
              color = 'grey',
              fillColor = 'grey',
              smoothFactor = 0,
              options = pathOptions(clickable = F),
              group = tss_grp)

# plot static speed reduction zone
map <- map %>%
  addPolygons(data=tc_zone, group = static_speed_grp,
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(5,5), options = pathOptions(clickable = F),
              weight = .25, color = 'grey', fillColor = 'grey')

# plot dynamic speed reduction zone
map <- map %>%
  addPolygons(data=tc_lanes, group = dynamic_speed_grp,
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(5,5), options = pathOptions(clickable = F),
              weight = .25, color = 'purple', fillColor = 'purple')

# plot static fisheries closue
map <- map %>%
  addPolygons(data=static_zone, group = static_fish_grp,
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
      addPolylines(data=tracks.df[[df]], group = survey_grp,
                   lng=~lon, lat=~lat, weight = 2,
                   smoothFactor = 1, color = getColor(tracks.df[[df]]))
  })

# add platform icons ------------------------------------------------------

if(file.exists(lfile)){

  # add icons for latest position of live dcs platforms
  map <- map %>% addMarkers(data = latest, ~lon, ~lat, icon = ~dcsIcons[platform],
                            popup = ~paste(sep = "<br/>",
                                           strong('Latest position / 
                                                  position la plus récente'),
                                           paste0('Time / heure: ', 
                                                  as.character(time), ' UTC'),
                                           paste0('Position / position: ',
                                                  as.character(round(lat,2)), ', ', 
                                                  as.character(round(lon,2)))
                            ),
                            group = robot_grp)
}

# add definite detections/sightings ---------------------------------------

map <- map %>% addCircleMarkers(data = det, ~lon, ~lat, group = rw_grp,
                 radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                 fillColor = pal(det$score),
                 popup = ~paste(sep = "<br/>" ,
                                strong('Right whale / baleine noire'),
                                paste0("Number / nombre: ", number),
                                paste0('Date / date: ', as.character(date)),
                                paste0('Position / position: ',
                                       as.character(round(lat,2)), ', ', 
                                       as.character(round(lon,2)))
                                ),
                 options = markerOptions(removeOutsideVisibleBounds=T))

# save widget -------------------------------------------------------------

saveWidget(widget = map, file = fout, selfcontained = T)
