# server.R
# WhaleMap - a Shiny app for visualizing whale survey data

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
  observations = readRDS('data/processed/observations.rds')
 
  # build date UI -------------------------------------------------------
  
  output$dateChoice <- renderUI({

    switch(input$dateType,
           'select' = dateInput('date', label = NULL,
                                value = Sys.Date()),
           
           'range' = dateRangeInput('date', label = NULL,
                                    start = Sys.Date() - tlag, end = Sys.Date()),
           
           'multiyear' = list(
             sliderInput('date', label = NULL, 
                         min = as.Date('2019-01-01'), 
                         max = as.Date('2019-12-31'),
                         value = c(Sys.Date()-tlag, Sys.Date()), 
                         step = 1,
                         timeFormat = '%b-%d',
                         animate = F),
             selectInput('years', label = NULL, choices = seq(2014,2019,1), 
                         selected = 2019, multiple = TRUE, selectize = TRUE)
           )
    )
  })

  # choose date -------------------------------------------------------
  
  dates <- reactive({
    
    # catch startup error
    if(is.null(input$date)){
      return(seq(Sys.Date()-tlag, Sys.Date(), 1))
    }
    
    # select date from variable inputs
    if(input$dateType == 'select'){
      
      input$date
      
    } else if(input$dateType == 'range'){
      
      seq(input$date[1], input$date[length(input$date)], 1)
      
    } else if(input$dateType == 'multiyear'){
      
      # require year (catch startup error)
      req(input$years)
      
      # sequence of year days between dates
      yd = seq(yday(input$date[1]), yday(input$date[length(input$date)]), 1)
      
      # convert to dates across years
      as.Date(
        unlist(
          lapply(X = input$years, FUN = function(x){
            as.Date(yd, origin = paste0(x,'-01-01'))
          })), 
        origin = '1970-01-01')-1
      
    }
  })
  
  # choose platform -----------------------------------------------------------
  
  platform <- reactive({
    input$platform
  })
  
  # name choices -----------------------------------------------------------
  
  # extract names of active platform(s)
  name_choices <- reactive({
    bind_rows(tracks[c('date', 'platform', 'name')], observations[c('date', 'platform', 'name')]) %>%
      filter(date %in% dates() & platform %in% platform()) %>%
      pull(name) %>%
      as.character() %>%
      unique()
  })
  
  # build name UI -----------------------------------------------------------
  
  output$nameChoice <- renderUI({
    
    # construct UI
    selectInput("name", "Choose platform name(s):", multiple = T,
                choices = c('All', name_choices()), 
                selected = 'All', selectize = TRUE)
    
  })
  
  # choose name -----------------------------------------------------------
  
  # name
  name <- reactive({
    if('All' %in% input$name | input$go == 0){
      name_choices()
    } else {
      input$name  
    }
  })
  
  # choose species -----------------------------------------------------------
  
  # species
  species <- eventReactive(input$go|input$go == 0,{
    input$species
  })
  
  # choose colors -----------------------------------------------------------
  
  colorby_obs <- eventReactive(input$go|input$go == 0,{
    input$colorby_obs  
  })
  
  colorby_trk <- eventReactive(input$go|input$go == 0,{
    input$colorby_trk  
  })
  
  pal_obs <- eventReactive(input$go|input$go == 0,{
    input$pal_obs  
  })
  
  pal_trk <- eventReactive(input$go|input$go == 0,{
    input$pal_trk  
  })
  
  # reactive data -----------------------------------------------------------
  
  # subset track data
  trk <- eventReactive(input$go|input$go == 0, {
    if(input$password == password){
      
      tracks %>%
        filter(
          date %in% dates() & 
            name %in% name() &
            platform %in% platform() 
        )
      
    } else if(input$password == jasco_password){
      
      tracks %>%
        filter(
          date %in% dates() & 
            platform %in% platform() & 
            name %in% name() &
            name != 'cp_king_air'
        )
      
    } else {
      
      tracks %>%
        filter(
          date %in% dates() & 
            platform %in% platform() & 
            name %in% name() &
            !name %in% c('cp_king_air','jasco_test')
        )
      
    }
  })
  
  # subset observation data
  obs <- eventReactive(input$go|input$go == 0, {
    if(input$password == password){
      
      observations %>%
        filter(
          date %in% dates() & 
            platform %in% platform() & 
            name %in% name() &
            species %in% species()
        ) %>%
        droplevels()
      
    } else if(input$password == jasco_password){
      
      observations %>%
        filter(
          date %in% dates() & 
            platform %in% platform() & 
            species %in% species() &
            name %in% name() &
            score != 'possible visual'
        ) %>%
        droplevels()
      
    } else {
      
      observations %>%
        filter(
          date %in% dates() & 
            platform %in% platform() & 
            species %in% species() &
            name %in% name() &
            !name %in% c('jasco_test') &
            score != 'possible visual'
        ) %>%
        droplevels()
      
    }
  })
  
  # only possible
  pos <- eventReactive(input$go|input$go == 0, {
    
    obs() %>%
      filter(
        score %in% c('possible acoustic', 'possible visual')
      ) %>%
      droplevels()
    
  })
  
  # only definite
  det <- reactive({
    
    obs() %>%
      filter(
        score %in% c('definite acoustic', 'definite visual')
      ) %>%
      droplevels()
    
  })
  
  # combine track and observations
  allBounds <- reactive({
    
    # combine limits
    lat = c(obs()$lat, trk()$lat)
    lon = c(obs()$lon, trk()$lon)
    
    # join in list
    list(lat, lon)
  })
  
  # position for live dcs platform
  if(file.exists(lfile)){
    LATEST <- eventReactive(input$go|input$go == 0, {
      
      if(input$password == password | input$password == jasco_password){
        
        latest %>%
          filter(
            date %in% dates() & 
              name %in% name() &
              platform %in% platform()
          )
        
      } else {
        
        latest %>%
          filter(
            date %in% dates() & 
              platform %in% platform() &
              name %in% name() &
              name != 'jasco_test'
          )
        
      }
    })
  }
  
  # position for live dcs platform
  SONO <- eventReactive(input$go|input$go == 0, {
    sono %>%
      filter(
        date %in% dates()
      )
  })
  
  # release notification  ------------------------------------------
  
  # showNotification(
  #   ui = 'WhaleMap has some new features!',
  #   action = a(target="_blank", href = "https://whalemap.ocean.dal.ca/features.html", "Check them out here"), 
  #   duration = NULL, closeButton = T, type = 'message')
  
  # warnings --------------------------------------------------------
  
  # password warnings
  observeEvent(input$go,{
    if(input$password == password){
      showNotification('Password was correct! Showing unverified and/or test data...',
                       duration = 7, closeButton = T, type = 'message')
      
    } else if(input$password == jasco_password){
      showNotification('Password was correct! Showing JASCO test data...',
                       duration = 7, closeButton = T, type = 'message')
    } else {
      # no warning
    }
  })
  
  # general warnings
  observeEvent(input$go,{
    
    # track warning
    if(nrow(trk())>npts){
      showNotification(paste0('Warning! Tracklines have been turned off because 
                              you have chosen to plot more data than this application 
                              can currently handle (i.e. more than ', as.character(npts), ' points). 
                              Please select less data to view tracks.'), 
                       duration = 7, closeButton = T, type = 'warning')
    }
    
    # species warning
    if(paste(species(),collapse=',')!='right'){
      showNotification('Note: WhaleMap focuses on right whales. Other species
                              information is incomplete.', 
                       duration = 7, closeButton = T, type = 'warning')
    }
    
    # year warning
    if(min(year(dates()))<2017){
      showNotification('Note: Data before 2017 are incomplete.', 
                       duration = 7, closeButton = T, type = 'warning')
    }
    
  })
  
  # colorpals -----------------------------------------------------------------
  
  # define color palette for any column variable
  colorpal_obs <- reactive({
    
    # extract factor levels
    n = unique(obs()[,which(colnames(obs())==colorby_obs())])
    
    if(colorby_obs() %in% c('yday', 'lat', 'lon')){
      
      # use continuous palette
      colorNumeric(get_palette(pal = pal_obs(), n = length(n)), domain = n)
      
    } else if (colorby_obs() == 'number'){
      
      if(is.infinite(min(obs()$number, na.rm = T))){
        # define colorbar limits if 'number' is selected without sightings data
        colorNumeric(get_palette(pal = pal_obs(), n = length(n)), 
                     c(NA,0), na.color = 'darkgrey')
      } else {
        # use continuous palette
        colorNumeric(get_palette(pal = pal_obs(), n = length(n)), 
                     obs()$number, na.color = 'darkgrey')
      }
      
    } else if (colorby_obs() == 'score' & pal_obs() == 'Default'){
      
      # hard wire colors for score factor levels
      colorFactor(levels = c('definite acoustic', 'possible acoustic', 'possible visual', 'definite visual'), 
                  palette = c('red', 'yellow', 'grey', 'darkslategrey'))  
      
    } else {
      
      # color by factor level
      colorFactor(get_palette(pal_obs(), length(n)), n)  
      
    }
  })
  
  
  # define color palette for any column variable
  colorpal_trk <- reactive({
    
    if(colorby_trk() == 'platform' & pal_trk() == 'Default'){
      
      # hardwire colors for score factor levels
      colorFactor(
        levels = names(platform_cols),
        palette = as.character(platform_cols)
      )
      
    } else {
      
      # extract factor levels
      n = unique(trk()[,which(colnames(trk())==colorby_trk())])
      
      # color by factor level
      colorFactor(get_palette(pal = pal_trk(), n = length(n)), levels = n)
      
    }
  })
  
  # basemap -----------------------------------------------------------------
  
  output$map <- renderLeaflet({
    leaflet(tracks) %>% 
      fitBounds(~max(lon, na.rm = T), 
                ~min(lat, na.rm = T), 
                ~min(lon, na.rm = T), 
                ~max(lat, na.rm = T)) %>%
      
      # add extra map features
      addScaleBar(position = 'topright')%>%
      addFullscreenControl(pseudoFullscreen = TRUE) %>%
      addMeasure(
        primaryLengthUnit = "kilometers",
        secondaryLengthUnit = 'miles', 
        primaryAreaUnit = "hectares",
        secondaryAreaUnit="acres", 
        activeColor = "#006622",
        completedColor = "#004d1a",
        position = 'bottomleft')
  })
  
  # tile observer ------------------------------------------------------  
  
  observeEvent(input$basemap, {
    # add tile
    leafletProxy("map") %>%
      clearTiles() %>%
      addProviderTiles(providers[[input$basemap]], layerId = 'basemap')
  })
 
  # graticules ------------------------------------------------------

  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('graticules')
    
    if(input$graticules){
      
      # add graticules
      proxy %>%
        addSimpleGraticule(zoomIntervals = graticule_ints, 
                           group = 'graticules', 
                           showOriginLabel = FALSE)
      
      # switch to show/hide
      ifelse(input$graticules, showGroup(proxy, 'graticules'),
             hideGroup(proxy, 'graticules'))
    }
    
  })
  
  # critical habitat zone ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('critical_habitat_zone')
    
    if(input$critical_habitat_zone){
      
      # add mpas
      proxy %>%
        addPolygons(data=critical_habitat_zone,
                    group = 'critical_habitat_zone',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = F),
                    weight = 1, 
                    color = 'darkgreen', 
                    fillColor = 'darkgreen')
      
      # switch to show/hide
      ifelse(input$critical_habitat_zone, showGroup(proxy, 'critical_habitat_zone'),
             hideGroup(proxy, 'critical_habitat_zone'))
    }
    
  })
  
  # static fishing zone ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('static_fishing_zone')
    
    if(input$static_fishing_zone){
      
      # add polygons
      proxy %>%
        addPolygons(data=static_fishing_zone, group = 'static_fishing_zone',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = F),
                    weight = 1, 
                    color = 'darkblue', 
                    fillColor = 'darkblue')
      
      # switch to show/hide
      ifelse(input$static_fishing_zone, showGroup(proxy, 'static_fishing_zone'),
             hideGroup(proxy, 'static_fishing_zone'))
    }
    
  })
  
  # dynamic fishing zone ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dynamic_fishing_zone')
    
    if(input$dynamic_fishing_zone){
      
      # add polygons
      proxy %>%
        addPolygons(data=dynamic_fishing_zone, group = 'dynamic_fishing_zone',
                    fill = T, 
                    fillOpacity = 0.4, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = F),
                    weight = 1, 
                    color = 'orange', 
                    fillColor = 'orange') %>%
        addPolygons(data=critical_habitat_zone, group = 'dynamic_fishing_zone',
                    fill = T, 
                    fillOpacity = 0.4, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = F),
                    weight = 1, 
                    color = 'orange', 
                    fillColor = 'orange')
      
      # switch to show/hide
      ifelse(input$dynamic_fishing_zone, showGroup(proxy, 'dynamic_fishing_zone'),
             hideGroup(proxy, 'dynamic_fishing_zone'))
    }
    
  })
  
  # dynamic fishing grid ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dynamic_fishing_grid')
    
    if(input$dynamic_fishing_grid){
      
      # add polygons
      proxy %>%
        addPolygons(data=dynamic_fishing_grid, group = 'dynamic_fishing_grid',
                    fill = T, 
                    fillOpacity = 0.4, 
                    stroke = T, 
                    weight = 1, 
                    color = 'grey', 
                    fillColor = 'orange',
                    popup = ~paste0('Grid cell ID: ', ID)) %>%
        addPolygons(data=critical_habitat_grid, group = 'dynamic_fishing_grid',
                    fill = T, 
                    fillOpacity = 0.4, 
                    stroke = T, 
                    weight = 1, 
                    color = 'grey', 
                    fillColor = 'orange',
                    popup = ~paste0('Grid cell ID: ', Grid_Index))
      
      # switch to show/hide
      ifelse(input$dynamic_fishing_grid, showGroup(proxy, 'dynamic_fishing_grid'),
             hideGroup(proxy, 'dynamic_fishing_grid'))
    }
    
  })
  
  # dynamic fishing 10f contour ------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dynamic_fishing_10_fathom_contour')
    
    if(input$dynamic_fishing_10_fathom_contour){
      
      # add polygons
      proxy %>%
        addPolylines(data=dynamic_fishing_10_fathom_contour, 
                    group = 'dynamic_fishing_10_fathom_contour',
                    weight = 1, color = 'black')
      
      # switch to show/hide
      ifelse(input$dynamic_fishing_10_fathom_contour, 
             showGroup(proxy, 'dynamic_fishing_10_fathom_contour'),
             hideGroup(proxy, 'dynamic_fishing_10_fathom_contour'))
    }
    
  })
  
  # dynamic fishing 20f contour ------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dynamic_fishing_20_fathom_contour')
    
    if(input$dynamic_fishing_20_fathom_contour){
      
      # add polygons
      proxy %>%
        addPolylines(data=dynamic_fishing_20_fathom_contour, 
                     group = 'dynamic_fishing_20_fathom_contour',
                     weight = 1, color = 'grey')
      
      # switch to show/hide
      ifelse(input$dynamic_fishing_20_fathom_contour, 
             showGroup(proxy, 'dynamic_fishing_20_fathom_contour'),
             hideGroup(proxy, 'dynamic_fishing_20_fathom_contour'))
    }
    
  })
  
  # static shipping zone ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('static_shipping_zone')
    
    if(input$static_shipping_zone){
      
      # add polygons
      proxy %>%
        addPolylines(data=static_shipping_zone, group = 'static_shipping_zone',
                    options = pathOptions(clickable = F),
                    weight = 3, 
                    color = 'red')
      
      # switch to show/hide
      ifelse(input$static_shipping_zone, showGroup(proxy, 'static_shipping_zone'),
             hideGroup(proxy, 'static_shipping_zone'))
    }
    
  })
  
  # dynamic shipping zone ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dynamic_shipping_zone')
    
    if(input$dynamic_shipping_zone){
      
      # add polygons
      proxy %>%
        addPolygons(data=dynamic_shipping_zone, group = 'dynamic_shipping_zone',
                    fill = T, 
                    fillOpacity = 0.4, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = F),
                    weight = 1, 
                    color = 'purple', 
                    fillColor = 'purple')
      
      # switch to show/hide
      ifelse(input$dynamic_shipping_zone, showGroup(proxy, 'dynamic_shipping_zone'),
             hideGroup(proxy, 'dynamic_shipping_zone'))
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
                     color = 'grey',
                     options = pathOptions(clickable = F),
                     group = 'tss') %>%
        addPolygons(tss_polygons$lon, tss_polygons$lat,
                    weight = .5,
                    color = 'grey',
                    fillColor = 'grey',
                    # smoothFactor = 3,
                    options = pathOptions(clickable = F),
                    group = 'tss')
      
      # switch to show/hide
      ifelse(input$tss, showGroup(proxy, 'tss'),hideGroup(proxy, 'tss'))
    }
  
  })
  
  
  # track observer ------------------------------------------------------  
  
  # observe(priority = 3, {
  observeEvent(input$tracks|input$go|input$go == 0, priority = 3, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('tracks')
    
    # tracks
    
    if(input$tracks & nrow(trk())<npts){
      
      # set up polyline plotting
      tracks.df <- split(trk(), trk()$id)
      
      # get color palette
      pal = colorpal_trk()
      
      ind = which(colnames(trk())==colorby_trk())
      
      # add lines
      names(tracks.df) %>%
        purrr::walk( function(df) {
          proxy <<- proxy %>%
            addPolylines(data=tracks.df[[df]], 
                         group = 'tracks',
                         lng=~lon, 
                         lat=~lat, 
                         weight = 2,
                         smoothFactor = 1, 
                         options = markerOptions(removeOutsideVisibleBounds=TRUE, opacity = 0.5),
                         color = pal(tracks.df[[df]][1,ind]),
                         popup = paste0('Track ID: ', unique(tracks.df[[df]]$id)))
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
        proxy %>% 
          addMapPane("lts", zIndex = 350) %>%
          addMarkers(data = LATEST(), ~lon, ~lat, 
                             icon = ~dcsIcons[platform],
                             options=pathOptions(pane = "lts"),
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
  
  # possible observer ------------------------------------------------------  
  
  observe(priority = 2,{
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('possible')
    
    if(input$possible){
      
      # set up color palette plotting
      pal <- colorpal_obs()
      
      # possible detections
      addCircleMarkers(map = proxy, data = pos(), ~lon, ~lat, group = 'possible',
                       radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                       fillColor = pal(pos()[,which(colnames(pos())==colorby_obs())]),
                       popup = ~paste(sep = "<br/>" ,
                                      paste0("Species: ", species),
                                      paste0("Score: ", score),
                                      paste0("Platform: ", platform),
                                      paste0("Name: ", name),
                                      paste0('Date: ', as.character(date)),
                                      paste0('Time: ', as.character(format(time, '%H:%M:%S'))),
                                      paste0('Position: ',
                                             as.character(lat), ', ', as.character(lon)))
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
      pal <- colorpal_obs()
      
      # definite detections
      addCircleMarkers(map = proxy, data = det(), ~lon, ~lat, group = 'detected',
                       radius = 4, fillOpacity = 0.9, stroke = T, col = 'black', weight = 0.5,
                       fillColor = pal(det()[,which(colnames(det())==colorby_obs())]),
                       popup = ~paste(sep = "<br/>" ,
                                      paste0("Species: ", species),
                                      paste0("Score: ", score),
                                      paste0("Number: ", number),
                                      paste0("Platform: ", platform),
                                      paste0("Name: ", name),
                                      paste0('Date: ', as.character(date)),
                                      paste0('Time: ', as.character(format(time, '%H:%M:%S'))),
                                      paste0('Position: ', 
                                             as.character(lat), ', ', as.character(lon))),
                       options = markerOptions(removeOutsideVisibleBounds=T))
    }
  })
  
  # legend observer ------------------------------------------------------  
  
  observe({
    
    # define proxy
    proxy <- leafletProxy("map")
    
    # set up color palette for tracks
    pal_trk <- colorpal_trk()
    var_trk <- trk()[,which(colnames(trk())==colorby_trk())]
    
    # determine which dataset to use based on display switches
    if(input$detected & input$possible){
      dat <- rbind(det(),pos())
    } else if(input$detected & !input$possible){
      dat <- det()
    } else if(!input$detected & input$possible){
      dat <- pos()
    } else {
      proxy %>% clearControls() %>% 
        addLegend(position = "bottomright",labFormat = labelFormat(big.mark = ""),
                  pal = pal_trk, values = var_trk, 
                  title = paste0('Tracks by ', colorby_trk()))
      return(NULL)
    }
    
    # set up color palette for observations
    pal_obs <- colorpal_obs()
    var_obs <- dat[,which(colnames(dat)==colorby_obs())]
    
    # check numbers of plotting points
    ptrk = nrow(trk())<npts & input$tracks
    
    if(input$legend & ptrk & TRUE %in% c(input$detected, input$possible)){
      # plot tracks and observations
      
      proxy %>% clearControls() %>% 
        addLegend(position = "bottomright",labFormat = labelFormat(big.mark = ""),
                  pal = pal_obs, values = var_obs, 
                  title = paste0('Observations by ', colorby_obs())) %>%
        addLegend(position = "bottomright",labFormat = labelFormat(big.mark = ""),
                  pal = pal_trk, values = var_trk, 
                  title = paste0('Tracks by ', colorby_trk()))
      
    } else if(input$legend & TRUE %in% c(input$detected, input$possible)){
      # plot only observations
      
      proxy %>% clearControls() %>% 
        addLegend(position = "bottomright",labFormat = labelFormat(big.mark = ""),
                  pal = pal_obs, values = var_obs, 
                  title = paste0('Observations by ', colorby_obs()))
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
  
  # determine tracks in map bounds
  tInBounds <- reactive({
    if (is.null(input$map_bounds))
      return(trk()[FALSE,])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(trk(),
           lat >= latRng[1] & lat <= latRng[2] &
             lon >= lngRng[1] & lon <= lngRng[2])
  })
  
  # determine detections in map bounds
  dInBounds <- reactive({
    
    # determine which dataset to use based on display switches
    if(input$detected & input$possible){
      dat <- rbind(det(),pos())
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
    if(nrow(obs())==0){
      HTML('No data available...')
    } else {
      
      # list species names in bounds 
      spp_names = paste(levels(dInBounds()$species), collapse = ', ')
      
      # sighting/detection info
      str1 <- paste0('<strong>Species</strong>: ', spp_names)
      
      str2 <- paste0('<strong>Number of definite sighting events</strong>: ', 
                     nrow(dInBounds()[dInBounds()$score=='definite visual',]))
      
      str3 <- paste0('<strong>Number of whales sighted (includes duplicates)</strong>: ', 
                     sum(dInBounds()$number[dInBounds()$score=='definite visual'], na.rm = T))
      
      ifelse(input$possible, 
             t<-nrow(dInBounds()[dInBounds()$score=='possible visual',]),
             t<-0)
      
      str4 <- paste0('<strong>Number of possible sighting events</strong>: ', t)
      
      ifelse(input$possible, 
             u<-sum(dInBounds()$number[dInBounds()$score=='possible visual'], na.rm = T),
             u<-0)
      
      str5 <- paste0('<strong>Number of whales possibly sighted</strong>: ', u)
      
      str6 <- paste0('<strong>Number of definite detections</strong>: ', 
                     nrow(dInBounds()[dInBounds()$score=='definite acoustic',]))
      
      ifelse(input$possible, 
             v<-nrow(dInBounds()[dInBounds()$score=='possible acoustic',]),
             v<-0)
      
      str7 <- paste0('<strong>Number of possible detections</strong>: ', v)
      
      # earliest and latest observation info
      str8 <- paste0('<strong>Earliest observation</strong>: ', min(dInBounds()$date, na.rm = T))
      rec_ind = which.max(dInBounds()$date)
      
      str9 <- paste0('<strong>Most recent observation</strong>: ', dInBounds()$date[rec_ind])
      
      str10 <- paste0('<strong>Most recent position</strong>: ', 
                     dInBounds()$lat[rec_ind], ', ', dInBounds()$lon[rec_ind])
      
      # paste and render
      HTML(paste(str1, str2, str3, str4, str5, str6, str7, str8, str9, str10, sep = '<br/>'))
    }
  })
  
  # bargraph ----------------------------------------------------------------
  
  output$graph <- renderPlotly({
    
    # define input observations
    if(input$plotInBounds){
      # use only data within map bounds
      obs = dInBounds()
    } else {
      # use all input data
      obs = obs()  
    }
    
    # define input tracks
    if(input$plotInBounds){
      # use only data within map bounds
      tracks = tInBounds()
    } else {
      # use all input data
      tracks = trk()  
    }
    
    # conditionally remove possibles for plotting
    if(!input$possible){
      obs = obs[obs$score!='possible acoustic' & obs$score!='possible visual',]
    }
    
    # add bogus data to handle no observations
    if(nrow(obs)==0 & nrow(tracks)!=0){
      obs = observations[FALSE,]
      obs[1:2,] = rep(NA, ncol(obs))
      obs$score[1] = 'definite visual'
      obs$score[2] = 'definite acoustic'
    }
    
    # avoid error if no data selected or in map view
    if(nrow(obs)==0 & nrow(tracks)==0){
      return(NULL)
    }
    
    # make categories for facet plotting
    obs$cat = ''
    obs$cat[obs$score == 'definite visual' | obs$score == 'possible visual'] = 'Sighting events per day'
    obs$cat[obs$score == 'definite acoustic' | obs$score == 'possible acoustic'] = 'Acoustic detection events per day'
    
    # determine days with trackline effort
    vis_effort = unique(tracks$yday[tracks$platform %in% visual_platforms])
    aco_effort = unique(tracks$yday[tracks$platform %in% acoustic_platforms])
    eff = data.frame('yday' = c(vis_effort, aco_effort),
                     'cat' = c(rep('Sighting events per day',length(vis_effort)), 
                               rep('Acoustic detection events per day',length(aco_effort))),
                     'y' = -1)
    
    # determine number of factor levels to color
    ncol = length(unique(obs[,which(colnames(obs)==colorby_obs())]))
    
    # choose palette for discrete scale
    cols = get_palette(pal = pal_obs(), n = ncol)
    
    # define min and max yday
    min_yday = isolate(min(yday(dates())))
    max_yday = isolate(max(yday(dates())))
    
    if(colorby_obs() %in% c('number', 'lat','lon', 'year')){
      
      # replace all sightings/detections with '1' to facilitate stacked plotting
      obs$counter = 1
      
      if(colorby_obs() == 'year'){
        # convert year to factor
        obs$year = as.factor(obs$year)
      }
      
      # define palette for discrete scale
      fillcols = scale_fill_manual(values = cols, name = colorby_obs())
      
      # build plot
      g = ggplot(obs, aes(x = yday, y = counter))+
        geom_bar(stat = "identity", na.rm = T, aes_string(fill = paste0(colorby_obs())))+
        labs(x = '', y = '')+
        fillcols+
        facet_wrap(~cat, scales="free_y", nrow = 2)+
        scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"), 
                           breaks = seq(from = min_yday, to = max_yday, length.out = 6))+
        geom_point(data = eff, aes(x = yday, y=y), pch=45, cex = 3, col = 'blue')+
        aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))+
        expand_limits(x = c(min_yday, max_yday))
      
    } else {
      if(colorby_obs()=='score' & pal_obs() == 'Default'){
        
        # manually define colors based on score
        fillcols = scale_fill_manual(values = score_cols, name = colorby_obs())
        
        # order factors so possibles plot first
        obs$score <- factor(obs$score, 
                            levels=levels(obs$score)[order(levels(obs$score), decreasing = TRUE)])
        
      } else if(colorby_obs()=='yday'){
        
        # define colors for continuous scale
        fillcols = scale_fill_gradientn(colours = cols, name = colorby_obs())
        
      } else {
        
        # define palette for discrete scale
        fillcols = scale_fill_manual(values = cols, name = colorby_obs())
      }
      
      # build plot
      g = ggplot(obs, aes(x = yday))+
        geom_bar(stat = "count", na.rm = T, aes_string(fill = paste0(colorby_obs())))+
        labs(x = '', y = '')+
        fillcols+
        facet_wrap(~cat, scales="free_y", nrow = 2)+
        scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"), 
                           breaks = seq(from = min_yday, to = max_yday, length.out = 6))+
        geom_point(data = eff, aes(x = yday, y=y), pch=45, cex = 3, col = 'blue')+
        aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))+
        expand_limits(x = c(min_yday, max_yday))
    }
    
    # build interactive plot
    gg = ggplotly(g, dynamicTicks = F, tooltip = c("text", "count", "fill")) %>%
      layout(margin=list(r=120, l=70, t=40, b=70), showlegend = input$legend)
    gg$elementId <- NULL # remove widget id warning
    gg
  })
  
  # status table ------------------------------------------------------------
  
  # make status table
  sdf = make_status_table(status_file = status_file, index_file = index_file)
  
  # render table
  output$status = renderTable({sdf}, 
                              striped = TRUE,
                              sanitize.text.function = function(x) x,
                              hover = TRUE,
                              bordered = TRUE, colnames = TRUE,
                              align = 'l',
                              width = '100%')
  
  # session -----------------------------------------------------------------
  
  # Set this to "force" instead of TRUE for testing locally (without Shiny Server)
  session$allowReconnect(TRUE)
  
} # server
