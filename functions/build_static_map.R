# static map - english/french version

build_static_map = function(english=TRUE){
  
  # translation -------------------------------------------------------------
  
  if(english){
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
    rw_date = 'Date: '
    rw_position = 'Position: '
    
    # define basemap
    basemap = 'OpenStreetMap.Mapnik'
    
    # basemap labels
    basemap_grp = 'OpenStreetMap'
    blank_grp = 'Basemap'
    oceanmap_grp = 'Ocean basemap'
    
    # define layer labels
    survey_grp = 'Survey tracks'
    robot_grp = 'Latest robot positions'
    graticules_grp = 'Graticules'
    rw_grp = 'Right whale observations'
    mpa_grp = 'Protected areas'
    tss_grp = 'Shipping lanes'
    static_speed_grp = 'Static speed reduction zone'
    dynamic_speed_grp = 'Dynamic speed reduction zone'
    static_fish_grp = 'Static fisheries closure'
    forage_areas_grp = 'Area subject to temporary fishery closure protocol'
    
    # output path
    fout = '../server_index/whale_map_en.html'
    
  } else {
    
    # define category names
    acoustic_lab = 'Acoustique'
    visual_lab = 'Visuelle'
    
    # basemap title
    main_title = 'Observation des baleines noires'
    date_title = 'Données de:'
    
    # robot popup labels
    robot_main = 'Position la plus récente'
    robot_date = 'Heure: '
    robot_position = 'Position: '
    
    # robot popup labels
    rw_main = 'Baleine noire'
    rw_number = 'Nombre de baleines: '
    rw_date = 'Date: '
    rw_position = 'Position: '
    
    # define basemap
    basemap = 'OpenStreetMap.France'
    
    # basemap labels
    basemap_grp = 'OpenStreetMap-Français'
    blank_grp = 'Fond de carte'
    oceanmap_grp = 'Fond de l\'océan'
    
    # define layer labels
    survey_grp = 'Trajets suivis'
    robot_grp = 'Positions les plus récentes des robots'
    graticules_grp = 'Graticules'
    rw_grp = 'Observations de baleines noires'
    mpa_grp = 'Zones protégées'
    tss_grp = 'Couloirs de navigation'
    static_speed_grp = 'Zone statique de réduction de vitesse'
    dynamic_speed_grp = 'Zone dynamique de réduction de vitesse'
    static_fish_grp = 'Fermeture statique de la pêche'
    forage_areas_grp = 'Zones soumises au protocole de fermeture temporaire'
    
    # output path
    fout = '../server_index/whale_map_fr.html'
  }
  
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
  
  # time period to show (days)
  lag = 14
  start_date = Sys.Date()-lag
  
  # define score color palette
  obs_levs = c(acoustic_lab, visual_lab)
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
  
  # start basemap
  map <- leaflet() %>%
    
    # add ocean basemap
    addProviderTiles(providers[[basemap]], group=basemap_grp) %>%
    addProviderTiles(providers$CartoDB.PositronNoLabels, group=blank_grp) %>%
    addProviderTiles(providers$Esri.OceanBasemap, group=oceanmap_grp) %>%
    
    # title and last updated message
    addControl(position = "topright",
               paste0(
                 '<div align="center">',
                 '<strong>', main_title, '</strong>','<br>',
                 '<small>', date_title,'<br>',
                 format(start_date, '%Y-%m-%d'), ' - ',
                 format(Sys.Date(), '%Y-%m-%d'), '</small>',
                 '</div>')) %>%
    
    # layer control
    addLayersControl(
      baseGroups = c(
        basemap_grp,
        blank_grp,
        oceanmap_grp
      ),
      overlayGroups = c(survey_grp,
                        robot_grp,
                        rw_grp,
                        mpa_grp,
                        tss_grp,
                        static_speed_grp,
                        dynamic_speed_grp,
                        static_fish_grp,
                        forage_areas_grp
      ),
      options = layersControlOptions(collapsed = TRUE), position = 'topright') %>%
    
    # hide groups
    hideGroup(c(survey_grp,
                graticules_grp,
                static_speed_grp,
                dynamic_speed_grp,
                static_fish_grp,
                forage_areas_grp)) %>%
    
    # # use NOAA graticules
    # addWMSTiles(
    #   "https://gis.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer/",
    #   layers = c("1-degree grid", "5-degree grid"),
    #   options = WMSTileOptions(format = "image/png8", transparent = TRUE),
    #   attribution = NULL,group = graticules_grp) %>%
    
    # add legend
    addLegend(position = "bottomright",
              pal = pal,
              values = obs_levs) %>%
    
    # add extra map features
    addScaleBar(position = 'bottomleft')%>%
    addFullscreenControl(pseudoFullscreen = F)
  
  # center on entire region
  map <- setView(map = map, lng = -65, lat = 45, zoom = 5)
  
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
  
  # plot known foraging areas
  map <- map %>%
    addPolygons(data=forage_areas, group = forage_areas_grp,
                fill = T, 
                fillOpacity = 0.25, 
                stroke = T, 
                weight = 1, 
                color = 'darkslategrey', 
                fillColor = 'orange')
  
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
                                                 paste0(rw_date, as.character(date)),
                                                 paste0(rw_position,
                                                        as.character(round(lat,2)), ', ', 
                                                        as.character(round(lon,2)))
                                  ),
                                  options = markerOptions(removeOutsideVisibleBounds=T))
  
  # save widget -------------------------------------------------------------
  
  saveWidget(widget = map, file = fout, selfcontained = T)
}

# build english map
build_static_map(english = TRUE)
build_static_map(english = FALSE)

