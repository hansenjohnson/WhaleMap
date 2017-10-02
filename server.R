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
library(ggplot2)
# devtools::install_github("ropensci/plotly")
library(plotly)

# define color palette list to choose from
palette_list = list(heat.colors(200), oce.colorsTemperature(200),oce.colorsSalinity(200),oce.colorsDensity(200),oce.colorsChlorophyll(200),oce.colorsGebco(200),oce.colorsJet(200),oceColorsViridis(200))

# define score colors
score_cols = c('detected' = 'red', 'possibly detected' = 'yellow', 'sighted' = 'darkslategray')

# server ------------------------------------------------------------------

function(input, output, session){
  
  # advance date -------------------------------------------------------

  observeEvent(input$advance,{
    val <- input$range
    updateSliderInput(session, "range", value = c(val[1], val[2]+7),
                      min = as.Date('2016-01-01'), max = as.Date('2016-12-31'))
  })
  
  # adjust date -------------------------------------------------------
  
  yday0 = reactive({
    yday(as.Date(input$range[1]))
  })
  
  yday1 = reactive({
    yday(as.Date(input$range[2]))
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
    droplevels(OBS()[OBS()$species %in% input$species,])
  })
  
  # only possible
  pos <- reactive({
    droplevels(spp()[spp()$score=='possibly detected',])
  })

  # only definite
  det <- reactive({
    droplevels(spp()[spp()$score!='possibly detected',])
  })
  
  # colorpal -----------------------------------------------------------------
  
  # define color palette for any column variable
  colorpal <- reactive({
    ind = as.numeric(input$pal)
    if(input$colorby == 'yday'){
      colorNumeric(palette_list[[ind]], spp()$yday)  
    } else if (input$colorby == 'number'){
      if(is.infinite(min(spp()$number, na.rm = T))){
        colorNumeric(palette_list[[ind]], c(NA,0), na.color = 'darkgrey')
      } else {
        colorNumeric(palette_list[[ind]], spp()$number, na.color = 'darkgrey')
      }
    } else if (input$colorby == 'score'){
      colorFactor(levels = c('detected', 'possibly detected', 'sighted'), 
                  palette = c('red', 'yellow', 'darkslategray'))  
    } else {
      colorFactor(palette_list[[ind]], spp()[,which(colnames(spp())==input$colorby)])  
    }
  })
  
  # basemap -----------------------------------------------------------------
  
  output$map <- renderLeaflet({
    leaflet(tracks) %>% 
      addProviderTiles(providers$Esri.OceanBasemap) %>%
      fitBounds(~max(lon, na.rm = T), ~min(lat, na.rm = T), ~min(lon, na.rm = T), ~max(lat, na.rm = T)) %>%
      
      # use NOAA graticules
      addWMSTiles(
        "https://maps.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer/",
        layers = c("1-degree grid", "5-degree grid"),
        options = WMSTileOptions(format = "image/png8", transparent = TRUE),
        attribution = "NOAA") %>%
      
      # add extra map features
      addScaleBar(position = 'bottomleft')%>%
      addMeasure(primaryLengthUnit = "kilometers",secondaryLengthUnit = 'miles', primaryAreaUnit = "hectares",secondaryAreaUnit="acres", position = 'bottomleft')
  })
  
  # extract trackline color ------------------------------------------------  
  
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
  
  # map observer ------------------------------------------------------  
  
  observe({
    
    # define proxy
    proxy = leafletProxy("map")
    proxy %>% clearMarkers() %>% clearShapes()
    
    # add tracklines
    if(nrow(TRACKS()) == 0){
      # skip plotting tracks...
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
    }
    
    # add points
    
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
                     label = ~paste0( as.character(date), ': ', input$species,' whale ', 
                                      score, ' by ', name))
    
    # switch to show/hide possibles
    ifelse(input$possible, showGroup(proxy, 'possible'),hideGroup(proxy, 'possible'))
    
    # definite detections
    addCircleMarkers(map = proxy, data = det(), ~lon, ~lat, group = 'detected',
                     radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                     fillColor = pal(det()[,which(colnames(det())==input$colorby)]),
                     popup = ~paste(sep = "<br/>" ,
                                    paste0("Species: ", input$species),
                                    paste0("Score: ", score),
                                    paste0("Number: ", number),
                                    paste0("Platform: ", platform),
                                    paste0("Name: ", name),
                                    paste0('Time: ', as.character(time)),
                                    paste0('Position: ', 
                                           as.character(lat), ', ', as.character(lon))),
                     label = ~paste0( as.character(date), ': ', input$species,' whale ', 
                                      score, ' by ', name))
    
    # switch to show/hide detected
    ifelse(input$detected, showGroup(proxy, 'detected'),hideGroup(proxy, 'detected'))
    
    #proxy %>% clearControls()
    if (input$legend) {
      proxy %>% addLegend(position = "bottomright",
                          pal = pal, values = var, layerId = 'legend', title = input$colorby)
    } else {
      proxy %>% clearControls()
    }
  })
  
  # re-center ------------------------------------------------------  
  
  observeEvent(input$zoom,{
    leafletProxy("map") %>% fitBounds(max(OBS()$lon, na.rm = T), min(OBS()$lat, na.rm = T), min(OBS()$lon, na.rm = T), max(OBS()$lat, na.rm = T))
  })
  
  # inbounds stats ------------------------------------------------------  
  
  # determine deployments in map bounds
  tInBounds <- reactive({
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
  dInBounds <- reactive({
    if (is.null(input$map_bounds))
      return(spp()[FALSE,])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(spp(),
           lat >= latRng[1] & lat <= latRng[2] &
             lon >= lngRng[1] & lon <= lngRng[2])
  })
  
  # create text summary
  output$summary <- renderUI({
    if(nrow(spp())==0){
      HTML('No data available...')
    } else {
      
      # sighting/detection info
      str1 <- paste0('<strong>Species</strong>: ', input$species)
      str2 <- paste0('<strong>Number of sighting events</strong>: ', 
                     nrow(dInBounds()[dInBounds()$score=='sighted',]))
      str3 <- paste0('<strong>Number of whales sighted (includes duplicates)</strong>: ', 
                     sum(dInBounds()$number[dInBounds()$score=='sighted'], na.rm = T))
      str4 <- paste0('<strong>Number of definite detections</strong>: ', 
                     nrow(dInBounds()[dInBounds()$score=='detected',]))
      
      # possible detections (set to zero if button is turned off)
      ifelse(input$possible, 
             t<-nrow(dInBounds()[dInBounds()$score=='possibly detected',]),
             t<-0)
      str5 <- paste0('<strong>Number of possible detections</strong>: ', t)
      
      # earliest and latest observation info
      str6 <- paste0('<strong>Earliest observation</strong>: ', min(dInBounds()$date, na.rm = T))
      rec_ind = which.max(dInBounds()$date)
      str7 <- paste0('<strong>Most recent observation</strong>: ', dInBounds()$date[rec_ind])
      str8 <- paste0('<strong>Most recent position</strong>: ', 
                     dInBounds()$lat[rec_ind], ', ', dInBounds()$lon[rec_ind])
      
      # survey info
      # str8 <- paste0('<strong>Number of survey(s)</strong>: ', length(unique(tInBounds()$id)))
      # str9 <- paste0('<strong>Number of track points</strong>: ', nrow(tInBounds()))
      # str10 <- paste('<strong>Survey ID(s)</strong>:<br/>', 
      #               paste(unique(c(as.character(dInBounds()$id),
      #                              as.character(tInBounds()$id))), collapse = '<br/>'))
      
      # paste and render
      HTML(paste(str1, str2, str3, str4, str5, str6, str7, str8, sep = '<br/>'))
    }
  })
  
  # bargraph ----------------------------------------------------------------
  
  output$graph <- renderPlotly({
    
    # determine input data
    if(input$plotInBounds){
      
      # use only data within map bounds
      obs = dInBounds()
      
    } else {
      
      # use all input data
      obs = spp()  
      
    }
    
    # conditionally remove possibles for plotting
    if(!input$possible){
      obs = obs[obs$score!='possibly detected',]
    }
    
    # avoid error if no data selected or in map view
    if(nrow(obs)==0){
      return(NULL)
    }
    
    # replace all sightings/detections with '1' to facilitate stacked plotting
    obs$number = 1
    
    # make categories for facet plotting
    obs$cat = ''
    obs$cat[obs$score == 'sighted'] = 'Sightings per day'
    obs$cat[obs$score != 'sighted'] = 'Detections per day'
    
    # determine number of factor levels to color
    ncol = length(unique(obs[,which(colnames(obs)==input$colorby)]))
    
    # get input for color palette choice
    ind = as.numeric(input$pal)
    
    # define colors
    if(input$colorby=='score'){
      
      # manually define colors based on score
      fillcols = scale_fill_manual(values = score_cols, name = input$colorby)
      
      # order factors so possibles plot first
      obs$score <- factor(obs$score, 
                          levels=levels(obs$score)[order(levels(obs$score), decreasing = TRUE)])
      
    } else if(input$colorby=='yday'|input$colorby=='number'){
      
      # choose palette for continuous scale
      cols = palette_list[[ind]]
      
      # define colors for continuous scale
      fillcols = scale_fill_gradientn(colours = cols, name = input$colorby)
      
    } else{
      
      # list palettes for discrete scale
      palette_list2 = list(heat.colors(ncol), oce.colorsTemperature(ncol),oce.colorsSalinity(ncol),oce.colorsDensity(ncol),oce.colorsChlorophyll(ncol),oce.colorsGebco(ncol),oce.colorsJet(ncol),oceColorsViridis(ncol))
      
      # choose palette for discrete scale
      cols = palette_list2[[ind]]
      
      # define palette for discrete scale
      fillcols = scale_fill_manual(values = cols, name = input$colorby)
      
    }
    
    # build plot
    g = ggplot(obs, aes(x = yday))+
      geom_histogram(stat = "count", colour="black", size = 0.1, aes_string(fill = paste0(input$colorby)))+
      labs(x = '', y = '')+
      fillcols+
      facet_wrap(~cat, scales="free_y", nrow = 2)+
      scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"))+
      aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))+
      theme_bw()
    
    # plot
    gg = ggplotly(g, dynamicTicks = F, tooltip = c("text", "count", "fill")) %>%
      layout(margin=list(r=120, l=70, t=40, b=70), showlegend = input$legend)
  })
  
}



