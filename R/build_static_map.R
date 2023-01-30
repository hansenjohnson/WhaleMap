## build_static_map ##
# build standalone html summary map from whalemap data

# definitions -------------------------------------------------------------

# define category names
acoustic_lab = 'Acoustic'
visual_lab = 'Visual'

# basemap title
main_title = 'Right whale observations'
date_title = 'Data from:'

# robot popup labels
robot_main = 'Latest position'
robot_date = 'Time: '
robot_position = 'Position: '

# robot popup labels
rw_main = 'Right whale'
rw_number = 'Number of whales: '
rw_calves = 'Number of calves: '
rw_date = 'Date: '
rw_position = 'Position: '

# define layer labels
survey_grp = 'Survey tracks'
robot_grp = 'Latest robot positions'
graticules_grp = 'Graticules'
rw_grp = 'Right whale observations'
tss_grp = 'Shipping lanes'
mpa_grp = 'Canadian protected areas'
tc_zone_grp = 'Canadian speed reduction zones'
dfo_zone_grp = 'Areas subject to Canadian fishery closure protocol'
sma_grp = 'US seasonal management areas'
dma_grp = 'US right whale slow zones'
alwtrp_grp = 'US fishery seasonal restricted areas'

# output path
fout = './static_map/whalemap.html'  

# setup -------------------------------------------------------------------

# required libraries
suppressPackageStartupMessages(library(leaflet))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(htmltools))
suppressPackageStartupMessages(library(htmlwidgets))
suppressPackageStartupMessages(library(maptools))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(oce))
suppressPackageStartupMessages(library(leaflet.extras))
suppressPackageStartupMessages(library(leaflegend))

# time period to show (days)
t1 = as.Date(format(Sys.time(), "%Y-%m-%d", tz = 'UTC'))
t0 = t1-14

# define score color palette
obs_levs = c(acoustic_lab, visual_lab)
obs_pal = c('red', 'darkslategray')
pal = colorFactor(levels = obs_levs,
                  palette = obs_pal)

# make dcs icons
dcsIcons = iconList(
  slocum = makeIcon("icons/slocum.png", iconWidth = 38, iconHeight = 38),
  buoy = makeIcon("icons/buoy.png", iconWidth = 44, iconHeight = 34, iconAnchorX = 22, iconAnchorY = 28)
)

# define function to determine trackline color
getColor <- function(tracks) {
  if(tracks$platform[1] == 'slocum') {
    "blue"
  } else if(tracks$platform[1] == 'plane') {
    "#8B6914"
  } else if(tracks$platform[1] == 'vessel'){
    "black"
  } else {
    "darkgrey"
  }
}

# create destination directory
outdir = dirname(fout)
if(!dir.exists(outdir)){dir.create(outdir)}

# read in data -------------------------------------------------------

# read in map data
load('data/processed/tss.rda')
load('data/processed/gis.rda')
load('data/processed/dma.rda')
load('data/processed/sma.rda')

# tracklines
tracks = readRDS('data/processed/effort.rds')

# latest dcs positions
lfile = 'data/processed/dcs_live_latest_position.rds'
if(file.exists(lfile)){
  latest = readRDS(lfile)
}

# sightings / detections
obs = readRDS('data/processed/observations.rds')

# subset data -------------------------------------------------------------

# tracklines
Tracks = tracks[tracks$date >= t0,]; rm(tracks)

# observations
Obs = obs[obs$date >= t0,]; rm(obs)

# select species
spp = Obs[Obs$species == 'right',]

# only definite
det = droplevels(spp[!spp$score %in% c('possible acoustic', 'possible visual'),])

# rename factor levels
det$score = gsub(pattern = 'definite visual', replacement = visual_lab, x = det$score)
det$score = gsub(pattern = 'definite acoustic', replacement = acoustic_lab, x = det$score)
det$score = as.factor(det$score) 

# legend icons ------------------------------------------------------------

sym = makeSymbolIcons(shape = 'circle', 
                      fillColor = obs_pal,
                      color = 'black',
                      opacity = 1,
                      fillOpacity = 0.9, 
                      strokeWidth = 1,
                      width = 10,
                      height = 10,
                      weight = 2)

# basemap -----------------------------------------------------------------

# add basemap tiles
map <- leaflet() %>%
  addWMSTiles(baseUrl = "https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}", layers = "Ocean_World_Ocean_Base") %>%
  addWMSTiles(baseUrl = "https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Reference/MapServer/tile/{z}/{y}/{x}", 
              layers = "Ocean_World_Ocean_Reference", attribution = 'Tiles &copy; Esri &mdash; Sources: GEBCO, NOAA, CHS, OSU, UNH, CSUMB, National Geographic, DeLorme, NAVTEQ, and Esri')

# title and last updated message
map <- map %>% 
  addControl(position = "topright",
             paste0(
               '<div align="center">',
               '<strong>', main_title, '</strong>','<br>',
               '<small>', date_title,'<br>',
               format(t0, '%Y-%m-%d'), ' - ',
               format(t1, '%Y-%m-%d'), '</small>',
               '</div>'))

# layer control
map <- map %>% addLayersControl(
  overlayGroups = c(survey_grp,
                    robot_grp,
                    rw_grp,
                    tss_grp,
                    mpa_grp,
                    tc_zone_grp,
                    dfo_zone_grp,
                    sma_grp,
                    alwtrp_grp,
                    dma_grp),
  options = layersControlOptions(collapsed = TRUE), position = 'topright')

# hide groups
map <- map %>% hideGroup(c(graticules_grp,
                           tc_zone_grp,
                           dfo_zone_grp,
                           alwtrp_grp)) %>%
  
  # add legend
  addLegendImage(
    position = 'bottomright',
    images = sym$iconUrl, 
    height = 12, width = 12,
    labelStyle = "font-size: 12px",
    labels = obs_levs) %>%
  
  # add extra map features
  addScaleBar(position = 'bottomleft')%>%
  addFullscreenControl(pseudoFullscreen = F)

# center on entire region
map <- setView(map = map, lng = -70, lat = 40, zoom = 4)

# plot polygons -----------------------------------------------------------

# add mpas
map <- map %>%
  addPolygons(data=critical_habitat_zone, group = mpa_grp,
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(5,5), options = pathOptions(clickable = F),
              weight = 1, color = 'darkgreen', fillColor = 'darkgreen')

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
              group = tss_grp) %>%
  addPolygons(data = tss_usa,
              weight = .5,
              color = 'grey',
              fillColor = 'grey',
              smoothFactor = 0,
              options = pathOptions(clickable = F),
              group = tss_grp)

# plot tc zone
map <- map %>%
  addPolygons(data=tc_zone, group = tc_zone_grp,
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(2,2), popup = ~paste0(ID),
              weight = 1, color = 'darkgreen', fillColor = 'darkgreen')

# plot dfo_zone
map <- map %>%
  addPolygons(data=dfo_zone, group = dfo_zone_grp,
              fill = T, fillOpacity = 0.25, stroke = T, smoothFactor = 0,
              dashArray = c(2,2), options = pathOptions(clickable = F),
              weight = 1, color = 'darkblue', fillColor = 'darkblue')

# plot US SMAs
map <- map %>%
  addPolygons(data=sma, group = sma_grp,
              fill = T, fillOpacity = 0.3, stroke = T, smoothFactor = 0,
              popup = ~paste(sep = "<br/>" ,
                             "US Seasonal Management Area",
                             paste0(NAME)),
              weight = 1, color = 'red', fillColor = 'red') 

# plot US ALWTRP
map <- map %>%
  addPolygons(data=alwtrp, group = alwtrp_grp,
              fill = T, fillOpacity = 0.3, stroke = T, smoothFactor = 0,
              popup = ~paste(sep = "<br/>" ,
                             alwtrp_grp,
                             paste0(ID),
                             paste0("Active: ", ACTIVE)),
              weight = 1, color = 'brown2', fillColor = 'brown2') 

# plot US DMAs
map <- map %>%
  addPolygons(data=dma, group = dma_grp,
              fill = T, fillOpacity = 0.3, stroke = T, smoothFactor = 0,
              dashArray = c(2,2), 
              popup = ~paste(sep = "<br/>" ,
                             "US Slow Zone",
                             paste0(NAME),
                             # paste0("Type: ", triggertype),
                             paste0("Expires: ", EXPDATE)),
              weight = 1, color = 'yellow', fillColor = 'yellow') 

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
  map <- map %>% 
    addMapPane("lts", zIndex = 350) %>%
    addMarkers(data = latest, ~lon, ~lat, icon = ~dcsIcons[platform],
               options=pathOptions(pane = "lts"),
                            popup = ~paste(sep = "<br/>",
                                           strong(robot_main),
                                           paste0(robot_date, 
                                                  as.character(time), ' UTC'),
                                           paste0(robot_position,
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
                                               strong(rw_main),
                                               paste0(rw_number, number),
                                               paste0(rw_calves, calves),
                                               paste0(rw_date, as.character(date)),
                                               paste0(rw_position,
                                                      as.character(round(lat,2)), ', ', 
                                                      as.character(round(lon,2)))
                                ),
                                options = markerOptions(removeOutsideVisibleBounds=T))

# save widget -------------------------------------------------------------

# normalize output path
FOUT = file.path(normalizePath(dirname(fout)),basename(fout))

# save widget
saveWidget(widget = map, file = FOUT, selfcontained = T)
