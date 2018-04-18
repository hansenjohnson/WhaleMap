# server.R
# WhaleMap - a Shiny app for visualizing whale survey data

# setup -------------------------------------------------------------------

# required libraries
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
library(plotly)
library(leaflet.extras)
# devtools::install_github("jrowen/rhandsontable")
library(rhandsontable)

# define color palette list to choose from
palette_list = list(heat.colors(200), 
                    oce.colorsTemperature(200),
                    oce.colorsSalinity(200),
                    oce.colorsDensity(200),
                    oce.colorsChlorophyll(200),
                    oce.colorsGebco(200),
                    oce.colorsJet(200),
                    oceColorsViridis(200))

# define score colors
score_cols = c('detected' = 'red', 
               'possibly detected' = 'yellow', 
               'sighted' = 'darkslategray',
               'possibly sighted' = 'gray')

# read in map polygons
mpa = readRDS('data/processed/mpa.rds')
load('data/processed/tss.rda')

# define track point plotting threshold
npts = 250000

# make dcs icons
dcsIcons = iconList(
  slocum = makeIcon("icons/slocum.png", iconWidth = 40, iconHeight = 40),
  wave = makeIcon("icons/wave.png", iconWidth = 35, iconHeight = 30),
  buoy = makeIcon("icons/buoy.png", iconWidth = 50, iconHeight = 40)
)

# read in password file
load('password.rda')

# server ------------------------------------------------------------------

function(input, output, session){
  
  # read in data -------------------------------------------------------
  
  # tracklines
  tracks = readRDS('data/processed/tracks.rds')
  
  # latest dcs positions
  lfile = 'data/processed/dcs_live_latest_position.rds'
  if(file.exists(lfile)){
    latest = readRDS(lfile) 
  }
  
  # sightings / detections
  obs = readRDS('data/processed/observations.rds')
  
  # sonobuoys
  sono = readRDS('data/processed/sonobuoys.rds')
  
  # build year UI -------------------------------------------------------
  
  output$yearChoice <- renderUI({
    
    # define year choices based on input data
    min_yr = min(as.numeric(obs$year), na.rm = T)
    max_yr = max(as.numeric(obs$year), na.rm = T)
    
    # change input depending on user choice
    switch(input$yearType,
           
           'select' = selectInput("year", label = NULL,
                                  choices = as.character(seq(max_yr, min_yr, -1)),
                                  selected = '2018', multiple = T),
           
           'range' = sliderInput("year", label = NULL,
                                 min = min_yr, max = max_yr, step = 1, 
                                 value = c(min_yr, max_yr), sep = "")
    )
  })
  
  # choose date -------------------------------------------------------
  
  # reactive
  yday0 = eventReactive(input$go, {
    yday(as.Date(input$range[1]))
  }, ignoreNULL = F)

  yday1 = eventReactive(input$go, {
    yday(as.Date(input$range[2]))
  }, ignoreNULL = F)
  
  # choose year -------------------------------------------------------
  
  years <- reactive({
    
    # assign default year if action button hasn't been pushed yet  
    if (input$go == 0){
      as.character('2018')
    } else {
      
      # choose year on action button click
      isolate({
        if(input$yearType == 'select'){
          as.character(input$year)
        } else if(input$yearType == 'range'){
          as.character(seq(input$year[1], input$year[2], 1))
        }
      })
    }
  })
  
  # choose species -----------------------------------------------------------
  
  species <- eventReactive(input$go|input$go == 0,{
    input$species
  })
  
  # choose platform -----------------------------------------------------------
  
  platform <- eventReactive(input$go|input$go == 0,{
    input$platform
  })
  
  # reactive data -----------------------------------------------------------
  
  # choose year(s) and platform(s)
  Tracks <- eventReactive(input$go|input$go == 0, {
    tmp = tracks[tracks$year %in% years(),]
    tmp[tmp$platform %in% platform(),]
  })
  
  Obs <- eventReactive(input$go|input$go == 0, {
    tmp = obs[obs$year %in% years(),]
    tmp[tmp$platform %in% platform(),]
  })
  
  # position for live dcs platform
  if(file.exists(lfile)){
    LATEST <- eventReactive(input$go|input$go == 0, {
      tmp = latest[latest$year %in% years(),]
      tmp = tmp[tmp$platform %in% platform(),]
      tmp[tmp$yday >= yday0() & tmp$yday <= yday1(),]
    })
  }
  
  # position for live dcs platform
  SONO <- eventReactive(input$go|input$go == 0, {
    tmp = sono[sono$year %in% years(),]
    tmp[tmp$yday >= yday0() & tmp$yday <= yday1(),]
  })
  
  # choose track date range
  TRACKS <- reactive({
    Tracks()[Tracks()$yday >= yday0() & Tracks()$yday <= yday1(),]
  })
  
  # choose species date range
  OBS <- reactive({
    Obs()[Obs()$yday >= yday0() & Obs()$yday <= yday1(),]
  })
  
  # choose species
  spp <- reactive({
    droplevels(OBS()[OBS()$species %in% species(),])
  })
  
  # only possible
  pos <- reactive({
    droplevels(spp()[spp()$score=='possibly detected'|spp()$score=='possibly sighted',])
  })
  
  # only definite
  det <- reactive({
    droplevels(spp()[spp()$score=='detected'|spp()$score=='sighted',])
  })
  
  # combine track and observations
  allBounds <- reactive({
    
    # combine limits
    lat = c(spp()$lat, TRACKS()$lat)
    lon = c(spp()$lon, TRACKS()$lon)
    
    # join in list
    list(lat, lon)
  })
  
  # password protected data -----------------------------------------------
  
  # observeEvent(input$go,{
  #   if(input$password == password){
  #     showNotification('Password was correct! Showing unverified data...\n
  #                      NOTE - this feature is not yet operational', 
  #                      duration = 7, closeButton = T, type = 'message')
  #   } else {
  #     showNotification('Password not provided or incorrect. Hiding unverified data...\n
  #                      NOTE - this feature is not yet operational', 
  #                      duration = 7, closeButton = T, type = 'warning')
  #     
  #     # REMOVE UNVERIFIED DATA
  #     
  #   }
  # })
  
  # track warning --------------------------------------------------------
  
  observe({
    if(nrow(TRACKS())>npts){
      showNotification(paste0('Warning! Tracklines have been turned off because you have chosen to plot more data than this application can currently handle (i.e. more than ', as.character(npts), ' points). Please select less data to view tracks.'), duration = 7, closeButton = T, type = 'warning')
    }
  })
  
  
  # colorpal -----------------------------------------------------------------
  
  # define color palette for any column variable
  colorpal <- reactive({
    
    # define index of color selection for use in palette list
    ind = as.numeric(input$pal)
    
    if(input$colorby %in% c('yday', 'lat', 'lon')){
      
      # use continuous palette
      colorNumeric(palette_list[[ind]], spp()[,which(colnames(spp())==input$colorby)])  
      
    } else if (input$colorby == 'number'){
      
      if(is.infinite(min(spp()$number, na.rm = T))){
        # define colorbar limits if 'number' is selected without sightings data
        colorNumeric(palette_list[[ind]], c(NA,0), na.color = 'darkgrey')
      } else {
        # use continuous palette
        colorNumeric(palette_list[[ind]], spp()$number, na.color = 'darkgrey')
      }
      
    } else if (input$colorby == 'year'){
      
      if(input$yearType=='range'){
        # use discrete palette if years are selected as a range
        colorNumeric(palette_list[[ind]], as.numeric(spp()$year))  
      } else {
        # use discrete palette if years are selected individually
        colorFactor(palette_list[[ind]], spp()$year)  
      }
      
    } else if (input$colorby == 'score'){
      
      # hard wire colors for score factor levels
      colorFactor(levels = c('detected', 'possibly detected', 'sighted'), 
                  palette = c('red', 'yellow', 'darkslategray'))  
      
    } else {
      
      # color by factor level
      colorFactor(palette_list[[ind]], spp()[,which(colnames(spp())==input$colorby)])  
      
    }
  })
  
  # basemap -----------------------------------------------------------------
  
  output$map <- renderLeaflet({
    leaflet(tracks) %>% 
      addProviderTiles(providers$Esri.OceanBasemap) %>%
      fitBounds(~max(lon, na.rm = T), 
                ~min(lat, na.rm = T), 
                ~min(lon, na.rm = T), 
                ~max(lat, na.rm = T)) %>%
      
      # add graticules
      # addWMSTiles(
      #   'https://gis.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer',
      #   layers = c('1', '2', '3'),
      #   options = WMSTileOptions(format = "image/png8", transparent = TRUE),
      #   attribution = "NOAA") %>%
      
      # use NOAA graticules
      addWMSTiles(
        "https://gis.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer/",
        layers = c("1-degree grid", "5-degree grid"),
        options = WMSTileOptions(format = "image/png8", transparent = TRUE),
        attribution = NULL) %>%
      
      # add extra map features
      addScaleBar(position = 'topright')%>%
      addFullscreenControl(pseudoFullscreen = TRUE) %>%
      addMeasure(
        primaryLengthUnit = "kilometers",
        secondaryLengthUnit = 'miles', 
        primaryAreaUnit = "hectares",
        secondaryAreaUnit="acres", 
        activeColor = "darkslategray",
        completedColor = "darkslategray",
        position = 'bottomleft') %>%
      addDrawToolbar(position = "topleft",
                     polylineOptions = F,
                     polygonOptions = F,
                     circleOptions = F,
                     rectangleOptions = F,
                     markerOptions = drawMarkerOptions(repeatMode = T), 
                     editOptions = editToolbarOptions(),
                     targetGroup = 'grp',
                     singleFeature = F
      )
    
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
  
  # mpa observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('mpa')
    
    if(input$mpa){
      
      # add mpas
      proxy %>%
        addPolygons(data=mpa, lng=~lon, lat=~lat, group = 'mpa',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    # smoothFactor = 3,
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = F),
                    weight = 1, 
                    color = 'grey', 
                    fillColor = 'grey')
      
      # switch to show/hide
      ifelse(input$mpa, showGroup(proxy, 'mpa'),hideGroup(proxy, 'mpa'))
    }
    
  })
  
  # tss observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('tss')
    
    if(input$tss){
      
      # plot shipping lanes

      proxy %>%
        addPolylines(tss_lines$lon, tss_lines$lat,
                     weight = .5,
                     color = 'red',
                     # smoothFactor = 3,
                     options = pathOptions(clickable = F),
                     group = 'tss') %>%
        addPolygons(tss_polygons$lon, tss_polygons$lat,
                    weight = .5,
                    color = 'red',
                    fillColor = 'red',
                    # smoothFactor = 3,
                    options = pathOptions(clickable = F),
                    group = 'tss')
      
      # switch to show/hide
      ifelse(input$tss, showGroup(proxy, 'tss'),hideGroup(proxy, 'tss'))
    }
  
  })
  
  
  # track observer ------------------------------------------------------  
  
  observe(priority = 3, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('tracks')
    
    # tracks
    
    if(input$tracks & nrow(TRACKS())<npts){
      
      # set up polyline plotting
      tracks.df <- split(TRACKS(), TRACKS()$id)
      
      # add lines
      names(tracks.df) %>%
        purrr::walk( function(df) {
          proxy <<- proxy %>%
            addPolylines(data=tracks.df[[df]], group = 'tracks',
                         lng=~lon, lat=~lat, weight = 2,
                         popup = paste0('Track ID: ', unique(tracks.df[[df]]$id)),
                         smoothFactor = 3, color = getColor(tracks.df[[df]]))
        })
    }
    
  })
  
  # latest observer ------------------------------------------------------  
  if(file.exists(lfile)){
    
    observe(priority = 3, {
      
      # define proxy
      proxy <- leafletProxy("map")
      proxy %>% clearGroup('latest')
      
      # tracks
      
      if(input$latest){
        
        # add icons for latest position of live dcs platforms
        proxy %>% addMarkers(data = LATEST(), ~lon, ~lat, icon = ~dcsIcons[platform],
                             popup = ~paste(sep = "<br/>",
                                            strong('Latest position'),
                                            paste0('Platform: ', as.character(platform)),
                                            paste0('Name: ', as.character(name)),
                                            paste0('Time: ', as.character(time), ' UTC'),
                                            paste0('Position: ', 
                                                   as.character(lat), ', ', as.character(lon))),
                             label = ~paste0('Latest position of ', as.character(name), ': ', 
                                             as.character(time), ' UTC'), group = 'latest')
        
      }
      
    })
  }
  
  # sono observer ------------------------------------------------------  
  
  observe(priority = 1, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('sono')
    
    # add sonobuoys
    if(input$sono){
      
      # add icons for latest position of live dcs platforms
      proxy %>% addMarkers(data = SONO(), ~lon, ~lat,group='sono',
                           popup = ~paste(sep = "<br/>",
                                          strong('Sonobuoy position'),
                                          paste0('Date: ', as.character(date)),
                                          paste0('Time: ', as.character(time), ' UTC'),
                                          paste0('ID: ', as.character(stn_id)),
                                          paste0('SN: ', as.character(sn)),
                                          paste0('Position: ', 
                                                 as.character(lat), ', ', as.character(lon)))
                           # label = ~paste0('sonobuoy ', as.character(stn_id), ': ', 
                           #                 as.character(date), ' UTC'), group = 'sono'
                           )
      
    }
    
  })
  
  # possible observer ------------------------------------------------------  
  
  observe(priority = 2,{
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('possible')
    
    if(input$possible){
      
      # set up color palette plotting
      pal <- colorpal()
      
      # possible detections
      addCircleMarkers(map = proxy, data = pos(), ~lon, ~lat, group = 'possible',
                       radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                       fillColor = pal(pos()[,which(colnames(pos())==input$colorby)]),
                       popup = ~paste(sep = "<br/>" ,
                                      strong("Sighting/Detection Details:"),
                                      paste0("Species: ", species),
                                      paste0("Score: ", score),
                                      paste0("Platform: ", platform),
                                      paste0("Name: ", name),
                                      paste0('Date: ', as.character(date)),
                                      paste0('Position: ',
                                             as.character(lat), ', ', as.character(lon)))
                       # label = ~paste0( as.character(date), ': ', species,' whale ', 
                       #                  score, ' by ', name)
                       )
    }
  })
  
  # definite observer ------------------------------------------------------  
  
  observe(priority = 1,{
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('detected')
    
    if(input$detected){
      
      # set up color palette plotting
      pal <- colorpal()
      
      # definite detections
      addCircleMarkers(map = proxy, data = det(), ~lon, ~lat, group = 'detected',
                       radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                       fillColor = pal(det()[,which(colnames(det())==input$colorby)]),
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
                       # label = ~paste0( as.character(date), ': ', species,' whale ', 
                       #                  score, ' by ', name), 
                       options = markerOptions(removeOutsideVisibleBounds=T))
                       # clusterOptions = markerClusterOptions(removeOutsideVisibleBounds = T,
                       #                        showCoverageOnHover = T,
                       #                        zoomToBoundsOnClick = T,
                       #                        disableClusteringAtZoom = 7,
                       #                        maxClusterRadius = 25))
      
    }
  })
  
  # legend observer ------------------------------------------------------  
  
  observe({
    
    # define proxy
    proxy <- leafletProxy("map")
    
    # determine which dataset to use based on display switches
    if(input$detected & input$possible){
      dat <- spp()
    } else if(input$detected & !input$possible){
      dat <- det()
    } else if(!input$detected & input$possible){
      dat <- pos()
    } else {
      proxy %>% clearControls()
      return(NULL)
    }
    
    # set up color palette plotting
    pal <- colorpal()
    var <- dat[,which(colnames(dat)==input$colorby)]
    
    # legend
    if(input$legend){
      proxy %>% clearControls() %>% 
        addLegend(position = "bottomright",labFormat = labelFormat(big.mark = ""),
                  pal = pal, values = var, 
                  title = input$colorby)
    } else {
      proxy %>% clearControls()
    }
  })
  
  # center map ------------------------------------------------------  
  
  observeEvent(input$zoom,{
    leafletProxy("map") %>% 
      fitBounds(max(allBounds()[[2]], na.rm = T), 
                min(allBounds()[[1]], na.rm = T), 
                min(allBounds()[[2]], na.rm = T), 
                max(allBounds()[[1]], na.rm = T))
  })
  
  # inbounds data ------------------------------------------------------  
  
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
    
    # determine which dataset to use based on display switches
    if(input$detected & input$possible){
      dat <- spp()
    } else if(input$detected & !input$possible){
      dat <- det()
    } else if(!input$detected & input$possible){
      dat <- pos()
    } else {
      dat = data.frame()
      return(dat[FALSE,])
    }
    
    # catch error if no data is displayed
    if (is.null(input$map_bounds)){
      return(dat[FALSE,])
    }
    
    # define map bounds
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    # subset of data in bounds
    subset(dat,
           lat >= latRng[1] & lat <= latRng[2] &
             lon >= lngRng[1] & lon <= lngRng[2])
  })
  
  # create text summary
  output$summary <- renderUI({
    if(nrow(spp())==0){
      HTML('No data available...')
    } else {
      
      # sighting/detection info
      str1 <- paste0('<strong>Species</strong>: ', species())
      
      str2 <- paste0('<strong>Number of definite sighting events</strong>: ', 
                     nrow(dInBounds()[dInBounds()$score=='sighted',]))
      
      str3 <- paste0('<strong>Number of whales sighted (includes duplicates)</strong>: ', 
                     sum(dInBounds()$number[dInBounds()$score=='sighted'], na.rm = T))
      
      ifelse(input$possible, 
             t<-nrow(dInBounds()[dInBounds()$score=='possibly sighted',]),
             t<-0)
      
      str4 <- paste0('<strong>Number of possible sighting events</strong>: ', t)
      
      ifelse(input$possible, 
             u<-sum(dInBounds()$number[dInBounds()$score=='possibly sighted'], na.rm = T),
             u<-0)
      
      str5 <- paste0('<strong>Number of whales possibly sighted</strong>: ', u)
      
      str6 <- paste0('<strong>Number of definite detections</strong>: ', 
                     nrow(dInBounds()[dInBounds()$score=='detected',]))
      
      ifelse(input$possible, 
             v<-nrow(dInBounds()[dInBounds()$score=='possibly detected',]),
             v<-0)
      
      str7 <- paste0('<strong>Number of possible detections</strong>: ', v)
      
      # earliest and latest observation info
      str8 <- paste0('<strong>Earliest observation</strong>: ', min(dInBounds()$date, na.rm = T))
      rec_ind = which.max(dInBounds()$date)
      
      str9 <- paste0('<strong>Most recent observation</strong>: ', dInBounds()$date[rec_ind])
      
      str10 <- paste0('<strong>Most recent position</strong>: ', 
                     dInBounds()$lat[rec_ind], ', ', dInBounds()$lon[rec_ind])
      
      # str8 <- paste0('<strong>Number of survey(s)</strong>: ', length(unique(tInBounds()$id)))
      # str9 <- paste0('<strong>Number of track points</strong>: ', nrow(tInBounds()))
      # str10 <- paste('<strong>Survey ID(s)</strong>:<br/>', 
      #               paste(unique(c(as.character(dInBounds()$id),
      #                              as.character(tInBounds()$id))), collapse = '<br/>'))
      
      # paste and render
      HTML(paste(str1, str2, str3, str4, str5, str6, str7, str8, str9, str10, sep = '<br/>'))
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
      obs = obs[obs$score!='possibly detected' & obs$score!='possibly sighted',]
    }
    
    # # remove na's for plotting (especially important for lat lons)
    # obs = obs[-c(which(is.na(obs$lat))),]
    
    # avoid error if no data selected or in map view
    if(nrow(obs)==0){
      return(NULL)
    }
    
    # make categories for facet plotting
    obs$cat = ''
    obs$cat[obs$score == 'sighted' | obs$score == 'possibly sighted'] = 'Sightings per day'
    obs$cat[obs$score == 'detected' | obs$score == 'possibly detected'] = 'Detections per day'
    
    # determine number of factor levels to color
    ncol = length(unique(obs[,which(colnames(obs)==input$colorby)]))
    
    # get input for color palette choice
    ind = as.numeric(input$pal)
    
    # list palettes for discrete scale (must be in the same order as palette_list)
    palette_list2 = list(heat.colors(ncol), 
                         oce.colorsTemperature(ncol),
                         oce.colorsSalinity(ncol),
                         oce.colorsDensity(ncol),
                         oce.colorsChlorophyll(ncol),
                         oce.colorsGebco(ncol),
                         oce.colorsJet(ncol),
                         oceColorsViridis(ncol))
    
    if(input$colorby %in% c('number','lat','lon', 'year')){
      
      # replace all sightings/detections with '1' to facilitate stacked plotting
      obs$counter = 1
      
      if(input$yearType == 'select' & input$colorby == 'year'){
        # convert year to factor
        obs$year = as.factor(obs$year)
        
        # choose palette for discrete scale
        cols = palette_list2[[ind]]
        
        # define palette for discrete scale
        fillcols = scale_fill_manual(values = cols, name = input$colorby)
        
      } else {
        
        # convert year to numeric
        if(input$colorby == 'year'){
          obs$year = as.numeric(obs$year)  
        }
        
        # choose palette for continuous scale
        cols = palette_list[[ind]]
        
        # define colors for continuous scale
        fillcols = scale_fill_gradientn(colours = cols, name = input$colorby)
      }
      
      # build plot
      g = ggplot(obs, aes(x = yday, y = counter))+
        geom_histogram(stat = "identity", na.rm = T, aes_string(fill = paste0(input$colorby)))+
        labs(x = '', y = '')+
        fillcols+
        facet_wrap(~cat, scales="free_y", nrow = 2)+
        scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"))+
        aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))
      
    } else {
      if(input$colorby=='score'){
        
        # manually define colors based on score
        fillcols = scale_fill_manual(values = score_cols, name = input$colorby)
        
        # order factors so possibles plot first
        obs$score <- factor(obs$score, 
                            levels=levels(obs$score)[order(levels(obs$score), decreasing = TRUE)])
        
      } else if(input$colorby=='yday'){
        
        # choose palette for continuous scale
        cols = palette_list[[ind]]
        
        # define colors for continuous scale
        fillcols = scale_fill_gradientn(colours = cols, name = input$colorby)
        
      } else {
        
        # choose palette for discrete scale
        cols = palette_list2[[ind]]
        
        # define palette for discrete scale
        fillcols = scale_fill_manual(values = cols, name = input$colorby)
      }
      
      # build plot
      g = ggplot(obs, aes(x = yday))+
        geom_histogram(stat = "count", na.rm = T, aes_string(fill = paste0(input$colorby)))+
        labs(x = '', y = '')+
        fillcols+
        facet_wrap(~cat, scales="free_y", nrow = 2)+
        scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"))+
        aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))
    }
    
    # plot
    gg = ggplotly(g, dynamicTicks = F, tooltip = c("text", "count", "fill")) %>%
      layout(margin=list(r=120, l=70, t=40, b=70), showlegend = input$legend)
  })
  
  # coordinate editor ----------------------------------------------------------  
  
  observeEvent(input$map_draw_all_features,{
    
    # extract lat lons of drawn objects
    f = input$map_draw_all_features
    lng = sapply(f$features, FUN = function(x) x$geometry$coordinates[[1]])
    lat = sapply(f$features, FUN = function(x) x$geometry$coordinates[[2]])
    
    # calculate along-path distance
    if(input$dist){
      
      # catch error if plot is cleared
      if(is.numeric(lng)){
        dist = geodDist(longitude1 = lng, latitude1 = lat, alongPath = T)
      } else {
        dist = NULL
      }
      
      DF = data.frame(lat, lng, dist)
    } else {
      DF = data.frame(lat, lng)
    }
    
    # construct table
    output$hot = renderRHandsontable({
      rhandsontable(DF, rowHeaders = NULL) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
      
    })
  })
  
  # round coordinates
  observeEvent(input$round,{
    DF = hot_to_r(input$hot)
    DF = round(DF, digits = input$dig)
    
    output$hot = renderRHandsontable({
      rhandsontable(DF, rowHeaders = NULL) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
    })
  })
  
  # update map after editing coordinates
  observe({
    if (is.null(input$hot))
      return()
    
    # read in values from table
    DF = hot_to_r(input$hot)
    
    # catch error for blank DF (e.g. after deleting all points)
    if(is.null(DF$lng)){
      leafletProxy("map") %>% clearGroup('add')
      return()
    }
    
    # replace old positions on map
    proxy = leafletProxy("map")
    
    proxy %>%
      removeDrawToolbar(clearFeatures=TRUE) %>%
      addDrawToolbar(position = "topleft",
                     polylineOptions = F,
                     polygonOptions = F,
                     circleOptions = F,
                     rectangleOptions = F,
                     markerOptions = drawMarkerOptions(repeatMode = T), 
                     editOptions = editToolbarOptions(),
                     targetGroup = 'grp',
                     singleFeature = F
      ) %>%
      addMarkers(data = DF, lng = ~lng, lat = ~lat, group = 'grp', 
                 label = ~paste0(lat, ', ', lng))
    
    if(input$shp == 'None'){
      proxy %>% 
        clearGroup('add')
    } else if (input$shp == 'Line'){
      proxy %>% 
        clearGroup('add')%>%
        addPolylines(data = DF, lng = ~lng, lat = ~lat, group = 'add')
    }else if (input$shp == 'Polygon'){
      proxy %>% 
        clearGroup('add')%>%
        addPolygons(data = DF, lng = ~lng, lat = ~lat, group = 'add')
    }
  })
  
  # download csv
  output$downloadData <- downloadHandler(
    filename = function() {
      "WhaleMap.csv"
    },
    content = function(file) {
      write.csv(hot_to_r(input$hot), file, row.names = FALSE)
    }
  )
  
} # server



