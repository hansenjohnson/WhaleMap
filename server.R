# server.R

# setup -------------------------------------------------------------------

library(shiny)
library(leaflet)
library(rgdal)
library(htmltools)
library(htmlwidgets)
library(maptools)
library(lubridate)
library(oce)
library(shinydashboard)

# define color palette list to choose from
palette_list = list(heat.colors(200), oce.colorsTemperature(200),oce.colorsSalinity(200),oce.colorsDensity(200),oce.colorsChlorophyll(200),oce.colorsGebco(200),oce.colorsJet(200),rev(oceColorsViridis(200)))

# server ------------------------------------------------------------------

function(input, output, session){
  
  # # advance date -------------------------------------------------------
  # 
  # observeEvent(input$advance,{
  #   val <- input$range
  #   updateSliderInput(session, "range", value = c(val[1], val[2]+7),
  #                     min = as.Date('2017-01-01'), max = as.Date('2017-12-30'))
  # })
  
  # adjust date -------------------------------------------------------
  
  yday0 = reactive({
    yday(input$range[1])
  })
  
  yday1 = reactive({
    yday(input$range[2])
  })
  
  # trackline data -------------------------------------------------------
  
  tracks = readRDS('data/processed/tracks.rds')
  
  # whale data -------------------------------------------------------
  
  obs = readRDS('data/processed/observations.rds')
  
  # reactive data -----------------------------------------------------------
  
  # choose year(s) and platform(s)
  Tracks <- reactive({
    tmp = tracks[tracks$year %in% input$year,]
    tmp[tmp$platform %in% input$platform,]
  })
  
  Obs <- reactive({
    tmp = obs[obs$year %in% input$year,]
    tmp[tmp$platform %in% input$platform,]
  })
    
  # choose date range
  TRACKS <- reactive({
    Tracks()[Tracks()$yday >= yday0() & Tracks()$yday <= yday1(),]
  })
  
  OBS <- reactive({
    Obs()[Obs()$yday >= yday0() & Obs()$yday <= yday1(),]
  })
  
  # choose species
  spp <- reactive({
    OBS()[OBS()$species %in% input$species,]
  })
  
  # only possible
  pos <- reactive({
    spp()[spp()$score=='possibly detected',]
  })

  # only definite
  det <- reactive({
    spp()[spp()$score!='possibly detected',]
  })
  
  # colorpal -----------------------------------------------------------------
  
  # define color palette for any column variable
  colorpal <- reactive({
    ind = as.numeric(input$pal)
    if(input$colorby == 'yday'){
      colorNumeric(palette_list[[ind]], spp()$yday)  
    } else if (input$colorby == 'score'){
      colorFactor(c('red','yellow','darkgrey'), spp()$score)  
    } else {
      colorFactor(palette_list[[ind]], spp()[,which(colnames(spp())==input$colorby)])  
    }
  })
  
  # basemap -----------------------------------------------------------------
  
  output$map <- renderLeaflet({
    leaflet(tracks) %>% 
      addProviderTiles(providers$Esri.OceanBasemap) %>%
      fitBounds(~max(lon, na.rm = T), ~min(lat, na.rm = T), ~min(lon, na.rm = T), ~max(lat, na.rm = T)) %>%
      
      # add extra map features
      # addMouseCoordinates(style = 'basic') %>%
      addScaleBar(position = 'bottomleft')%>%
      addMeasure(primaryLengthUnit = "kilometers",secondaryLengthUnit = 'miles', primaryAreaUnit = "hectares",secondaryAreaUnit="acres", position = 'bottomleft')
  })
  
  # map observer ------------------------------------------------------  
  
  getColor <- function(tracks) {
      if(tracks$platform[1] == 'slocum') {
        "blue"
      } else if(tracks$platform[1] == 'plane') {
        "#8B6914"
      } else if(tracks$platform[1] == 'vessel'){
        "#2E2E2E"
      } else if(tracks$platform[1] == 'wave'){
        "green"
      } else {
        "black"
      }
  }
  
  observe({
    
    # define proxy
    proxy = leafletProxy("map")
    proxy %>% clearMarkers() %>% clearShapes()
    
    if(nrow(TRACKS()) == 0){
      return(NULL)
    } else {
      
      # set up polyline plotting
      tracks.df <- split(TRACKS(), TRACKS()$id)
      
      # add lines
      names(tracks.df) %>%
        purrr::walk( function(df) {
          proxy <<- proxy %>%
            addPolylines(data=tracks.df[[df]],
                         lng=~lon, lat=~lat, weight = 2,
                         group = 'tracks', smoothFactor = 3, color = getColor(tracks.df[[df]]))
        })
      
      # switch to show/hide tracks
      ifelse(input$tracks, showGroup(proxy, 'tracks'),hideGroup(proxy, 'tracks'))
      
      # set up color palette plotting
      pal <- colorpal()
      ifelse(input$possible,
             var <- spp()[,which(colnames(spp())==input$colorby)],
             var <- det()[,which(colnames(det())==input$colorby)]
             )
      

      # possible detections
      addCircleMarkers(map = proxy, data = pos(), ~lon, ~lat, group = 'possible',
                       radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5, 
                       fillColor = pal(pos()[,which(colnames(pos())==input$colorby)]),
                       popup = ~paste(sep = "<br/>" ,
                                      paste0("Species: ", input$species),
                                      "Score: possible",
                                      paste0("Platform: ", platform),
                                      paste0("Name: ", name),
                                      paste0('Time: ', as.character(time)),
                                      paste0('Position: ',
                                             as.character(lat), ', ', as.character(lon))),
                       label = ~paste0( as.character(date), ': ', input$species,' whale ', score))

      # switch to show/hide possibles
      ifelse(input$possible, showGroup(proxy, 'possible'),hideGroup(proxy, 'possible'))
      
      # definite detections
      addCircleMarkers(map = proxy, data = det(), ~lon, ~lat, group = 'detected',
                       radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5, 
                       fillColor = pal(det()[,which(colnames(det())==input$colorby)]),
                       label = ~paste0( as.character(date), ': ', input$species,' whale ', score),
                       popup = ~paste(sep = "<br/>" ,
                                      paste0("Species: ", input$species),
                                      paste0("Score: ", score),
                                      paste0("Platform: ", platform),
                                      paste0("Name: ", name),
                                      paste0('Time: ', as.character(time)),
                                      paste0('Position: ', 
                                             as.character(lat), ', ', as.character(lon))))
      
      # switch to show/hide detected
      ifelse(input$detected, showGroup(proxy, 'detected'),hideGroup(proxy, 'detected'))
      
      #proxy %>% clearControls()
      if (input$legend) {
        proxy %>% addLegend(position = "bottomright",
                            pal = pal, values = var, layerId = 'legend', title = input$colorby)
      } else {
        proxy %>% clearControls()
      }
    }
  })
  
  # re-center ------------------------------------------------------  
  
  observeEvent(input$zoom,{
    leafletProxy("map") %>% fitBounds(max(TRACKS()$lon, na.rm = T), min(TRACKS()$lat, na.rm = T), min(TRACKS()$lon, na.rm = T), max(TRACKS()$lat, na.rm = T))
  })
  
  # inbounds stats ------------------------------------------------------  
  
  # determine deployments in map bounds
  detInBounds <- reactive({
    if (is.null(input$map_bounds))
      return(TRACKS()[FALSE,])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(TRACKS(),
           lat >= latRng[1] & lat <= latRng[2] &
             lon >= lngRng[1] & lon <= lngRng[2])
  })
  
  # determine detected calls in map bounds
  detectedInBounds <- reactive({
    if (is.null(input$map_bounds))
      return(spp()[FALSE,])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(spp(),
           lat >= latRng[1] & lat <= latRng[2] &
             lon >= lngRng[1] & lon <= lngRng[2])
  })
  
  # # determine possible calls in map bounds
  # possibleInBounds <- reactive({
  #   if (is.null(input$map_bounds))
  #     return(possible()[FALSE,])
  #   bounds <- input$map_bounds
  #   latRng <- range(bounds$north, bounds$south)
  #   lngRng <- range(bounds$east, bounds$west)
  #   
  #   subset(possible(),
  #          lat >= latRng[1] & lat <= latRng[2] &
  #            lon >= lngRng[1] & lon <= lngRng[2])
  # })
  
  # create text summary
  output$summary <- renderUI({
    if(nrow(spp())==0){
      HTML('No data available...')
    } else {
      str1 <- paste0('<strong>Deployment(s)</strong>: ', length(unique(detInBounds()$id)))
      t = paste(unique(detInBounds()$id), collapse = ', ')
      str2 <- paste('<strong>ID(s)</strong>:', t)
      str3 <- paste0('<strong>Species</strong>: ', input$species)
      str4 <- paste0('<strong>Definite detections</strong>: ', nrow(detectedInBounds()))
      #str5 <- paste0('<strong>Possible detections</strong>: ', nrow(possibleInBounds()))
      str6 <- paste0('<strong>Tally periods</strong>: ', nrow(detInBounds()))
      HTML(paste(str1, str2, str3, str4,str6, sep = '<br/>'))
    }
  })
}