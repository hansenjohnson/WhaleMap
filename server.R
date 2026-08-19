# server.R
# WhaleMap - a Shiny app for visualizing whale survey data

function(input, output, session){
  
  # NOTE: tracks, observations, latest positions, dma, and sma are no longer
  # read here. They're loaded once, application-wide, in global.R via
  # reactiveFileReader()/reactivePoll() (see get_tracks(), get_observations(),
  # get_latest(), get_dma(), get_sma()), which also keeps them refreshed
  # automatically whenever the underlying files change (e.g. from the cron
  # job) without needing a per-session re-read or an app restart.
  
  # build date UI -------------------------------------------------------
  
  output$dateChoice <- renderUI({
    
    switch(input$dateType,
           'select' = dateInput('date', label = NULL,
                                value = Sys.Date()),
           
           'range' = dateRangeInput('date', label = NULL,
                                    start = Sys.Date() - tlag, end = Sys.Date()),
           
           'multiyear' = list(
             sliderInput('date', label = NULL, 
                         min = as.Date(paste0(cyear,'-01-01')), 
                         max = as.Date(paste0(cyear,'-12-31')),
                         value = c(Sys.Date()-tlag, Sys.Date()), 
                         step = 1,
                         timeFormat = '%b-%d',
                         animate = F),
             selectInput('years', label = NULL, choices = seq(cyear,2010,-1), 
                         selected = cyear, multiple = TRUE, selectize = TRUE)
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
  
  # choose name -----------------------------------------------------------
  
  # name
  name <- reactive({
    if('All' %in% input$name | input$go == 0){
      name_choices
    } else {
      input$name
    }
  })
  
  # choose data source ------------------------------------------------------
  
  # data source
  dsource <- eventReactive(input$go|input$go == 0,{
    input$dsource
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
    if(input$password == password | input$password == test_password){
      
      get_tracks() %>%
        filter(
          date %in% dates() & 
            source %in% dsource() &
            name %in% name() &
            platform %in% platform() 
        )
      
    } else {
      
      get_tracks() %>%
        filter(
          date %in% dates() & 
            source %in% dsource() &
            name %in% name() &
            !(name %in% hidden_platforms) &
            platform %in% platform() 
        )
      
    }
  })
  
  # subset observation data
  obs <- eventReactive(input$go|input$go == 0, {
    if(input$password == password){
      
      get_observations() %>%
        filter(
          date %in% dates() & 
            source %in% dsource() &
            platform %in% platform() & 
            name %in% name() &
            species %in% species()
        ) %>%
        droplevels()
      
    } else if(input$password == test_password){
      
      get_observations() %>%
        filter(
          date %in% dates() & 
            source %in% dsource() &
            platform %in% platform() & 
            species %in% species() &
            name %in% name() &
            score != 'possible visual'
        ) %>%
        droplevels()
      
    } else {
      
      get_observations() %>%
        filter(
          date %in% dates() & 
            source %in% dsource() &
            platform %in% platform() & 
            species %in% species() &
            name %in% name() &
            !(name %in% hidden_platforms) &
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
  # (lfile / file.exists check now lives in global.R, run once at app startup)
  if(file.exists(lfile)){
    LATEST <- eventReactive(input$go|input$go == 0, {
      
      if(input$password == password){
        
        get_latest() %>%
          filter(
            date %in% dates() & 
              source %in% dsource() &
              name %in% name() &
              platform %in% platform()
          )
        
      } else {
        
        get_latest() %>%
          filter(
            date %in% dates() & 
              source %in% dsource() &
              name %in% name() &
              !(name %in% hidden_platforms) &
              platform %in% platform()
          )
        
      }
    })
  }
  
  # subset dma/sma data --------------------------------------------------
  # same event-gated pattern as trk()/obs()/LATEST() above, rather than
  # calling get_dma()/get_sma() directly from the polygon-drawing observers
  # below. Previously those observers called get_dma()/get_sma() directly,
  # which - unlike trk()/obs() - are NOT isolated inside an eventReactive,
  # so a background data refresh would redraw the DMA/SMA layer immediately,
  # independent of whatever tracks/observations are currently on screen.
  # Gating them the same way keeps the management-area overlays visually
  # consistent with the rest of the displayed data, only updating together
  # when "Go" is pressed.
  dma_data <- eventReactive(input$go|input$go == 0, {
    get_dma()
  })
  
  sma_data <- eventReactive(input$go|input$go == 0, {
    get_sma()
  })
  
  # show startup disclaimer -------------------------------------------------
  
  observe({
    showModal(
      ui = modalDialog(
        title = "Welcome!",
        tags$div(
          list(
            tags$p("When using WhaleMap, please keep the following in mind:"),
            tags$ul(
              tags$li("Because whales swim continuously, exact locations are obsolete within minutes of a sighting"), 
              tags$li("A specific date or date range may contain few or no detections. This does not mean whales were not present. Effort is typically limited to seasonal whale watches or researchers dedicated to locating seasonal habitats."), 
              tags$li("Right whales are likely to be present within Seasonal and Dynamic Management Areas and Slow Zones, even if no observations are illustrated.")
            ), 
            tags$br(""),
            tags$p(style="text-align:center;", "New to WhaleMap?", tags$a(href="https://whalemap.org/guide.html","Click here for a user guide"))
          )
        ),
        footer = tags$p(style="text-align:center;", tags$em("Mariners are urged to use caution and proceed at safe speeds in areas where whales occur.")),
        easyClose = TRUE,
        fade = TRUE
      )
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
      showNotification(h4('Password was correct! Showing unverified test data and removing plotting limits...'),
                       duration = NULL, closeButton = T, type = 'message')
    }
  })
  
  observeEvent(input$go,{
    if(input$password == test_password){
      showNotification(h4('Password was correct! Showing unverified test data...'),
                       duration = NULL, closeButton = T, type = 'message')
    }
  })
  
  # general warnings
  observeEvent(input$go,{
    
    # track warning
    if(nrow(trk())>npts & input$password != password){
      showNotification(h4(paste0('Warning! Tracklines have been turned off because 
                              you have attemped to plot too many points (i.e. more than ', format(npts, big.mark = ",", scientific = FALSE), '). 
                              Please select less data to view tracks.')), 
                       duration = 15, closeButton = T, type = 'error')
    }
    
    # species warning
    if(paste(species(),collapse=',')!='right'){
      showNotification(h4('Note: Most real-time reports focus on right whales, 
                          so data on other species may be incomplete.'), 
                       duration = 15, closeButton = T, type = 'error')
    }
    
    # year warning
    if(min(year(dates()))<2017){
      showNotification(h4('Note: Effort data before 2017 are incomplete.'), 
                       duration = 15, closeButton = T, type = 'error')
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
    
    # isolate() so this widget is built ONCE per session (using tracks data
    # as of whenever the session starts) and never gets rebuilt just because
    # the shared background poll in global.R detects the underlying file
    # changed. Without this, get_tracks() here is a live dependency: a
    # mid-session data refresh would tear down and rebuild the entire map
    # widget, resetting pan/zoom back to the default fitBounds() extent and
    # wiping every overlay layer (tracks/points/polygons), since those were
    # attached to the old widget instance via leafletProxy(). trk()/obs()
    # elsewhere are already safely isolated inside eventReactive(input$go),
    # so the actual filtered data a user is looking at was never at risk -
    # this was specifically about the base widget getting rebuilt out from
    # under them.
    leaflet(isolate(get_tracks())) %>% 
      
      # obsPane pins the possible/detected observation points above every
      # other layer, including the "lts" pane (zIndex 450) used for the
      # live-position icons. A fixed-zIndex pane like "lts" doesn't respect
      # normal add-order stacking, so simply reordering observer priorities
      # can't put points above it - this is the only reliable way to
      # guarantee points stay on top of tracks, polygons, AND icons
      # regardless of what order those layers happen to redraw in.
      addMapPane('obsPane', zIndex = 500) %>%
      
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
        position = 'bottomleft') %>%
      
      # leafgl hover cursor ---------------------------------------------
      # Different mechanism than the earlier attempt (which relied on
      # input$map_glify_mouseover/_mouseout - a Shiny-event bridge that
      # appears to only exist in leafgl's GitHub dev version, not the CRAN
      # release, and never fired). This instead uses the raw JS "hover"
      # callback that addGlPoints()/addGlPolylines() forward straight to
      # Leaflet.glify itself - the same underlying hit-testing mechanism
      # that already successfully powers click-to-popup on these layers, so
      # it's a mechanism we know is live in this installed version, not a
      # guess. It's purely client-side: no round trip to the server, so no
      # added lag. A generic mousemove listener resets the cursor to
      # default on every tick; Leaflet.glify's own hover hit-test then
      # overrides it back to a pointer, via the hover= callback passed into
      # each addGlPoints()/addGlPolylines() call below, only on ticks where
      # the mouse is actually over a rendered feature.
      htmlwidgets::onRender("
        function(el, x) {
          var map = this;
          map.on('mousemove', function(e) {
            map.getContainer().style.cursor = '';
          });
        }
      ")
    
    # addControlGPS(options = gpsOptions(position = "topleft", activate = FALSE, 
    #                                              autoCenter = TRUE, maxZoom = 8, 
    #                                              setView = TRUE))
  })
  
  # tile observer ------------------------------------------------------  
  
  observeEvent(input$basemap, {
    # add tiles
    
    if(input$basemap == 'Esri.OceanBasemap'){
      leafletProxy("map") %>%
        clearTiles() %>%
        addWMSTiles(baseUrl = "https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}", layers = "Ocean_World_Ocean_Base") %>%
        addWMSTiles(baseUrl = "https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Reference/MapServer/tile/{z}/{y}/{x}", 
                    layers = "Ocean_World_Ocean_Reference", attribution = 'Tiles &copy; Esri &mdash; Sources: GEBCO, NOAA, CHS, OSU, UNH, CSUMB, National Geographic, DeLorme, NAVTEQ, and Esri')
    } else {
      leafletProxy("map") %>%
        clearTiles() %>%
        addProviderTiles(providers[[input$basemap]], layerId = 'basemap')
    }
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
      
    }
    
  })
  
  # noaa charts ------------------------------------------------------
  
  # observe(priority = 4, {
  # 
  #   # define proxy
  #   proxy <- leafletProxy("map")
  #   proxy %>% clearGroup('noaa')
  # 
  #   if(input$noaa){
  # 
  #     # add noaa charts
  #     proxy %>%
  #       addWMSTiles(baseUrl = "https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/ENCOnline/MapServer/exts/MaritimeChartService/WMSServer")
  #       # addTiles(urlTemplate = '//tileservice.charts.noaa.gov/tiles/50000_1/{z}/{x}/{y}.png', group = 'noaa')
  # 
  #     # switch to show/hide
  #     ifelse(input$noaa, showGroup(proxy, 'noaa'),
  #            hideGroup(proxy, 'noaa'))
  #   }
  # 
  # })
  
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
      
    }
    
  })
  
  # dfo zone observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dfo_zone')
    
    if(input$dfo_zone){
      
      # add polygons
      proxy %>%
        addPolygons(data=dfo_zone, group = 'dfo_zone',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = T),
                    popup = ~paste0(ID),
                    weight = 1, 
                    color = 'darkblue', 
                    fillColor = 'darkblue')
      
    }
    
  })
  
  # dfo lines observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dfo_lines')
    
    if(input$dfo_lines){
      
      # add polygons
      proxy %>%
        addPolylines(data=dfo_10f, group = 'dfo_lines',
                     options = pathOptions(clickable = F),
                     weight = 1, 
                     dashArray = c(1,1), 
                     color = 'darkblue') %>%
        addPolylines(data=dfo_20f, group = 'dfo_lines',
                     options = pathOptions(clickable = F),
                     dashArray = c(5,5), 
                     weight = 1, 
                     color = 'darkblue')
      
    }
    
  })
  
  # full grid observer ------------------------------------------------------  
  
  # observe(priority = 4, {
  #   
  #   # define proxy
  #   proxy <- leafletProxy("map")
  #   proxy %>% clearGroup('full_grid')
  #   
  #   if(input$full_grid){
  #     
  #     # add polygons
  #     proxy %>%
  #       addPolygons(data = full_grid, 
  #                   color = 'grey',
  #                   group = 'full_grid',
  #                   weight = 2,
  #                   smoothFactor = 3, 
  #                   popup = ~paste0(Grid_Index))
  #     
  #     # switch to show/hide
  #     ifelse(input$full_grid, showGroup(proxy, 'full_grid'),
  #            hideGroup(proxy, 'full_grid'))
  #   }
  #   
  # })
  
  # tc zone observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('tc_zone')
    
    if(input$tc_zone){
      
      # add polygons
      proxy %>%
        addPolygons(data=tc_zone, group = 'tc_zone',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = T),
                    popup = ~paste0(ID),
                    weight = 1, 
                    color = 'darkgreen', 
                    fillColor = 'darkgreen')
      
    }
    
  })
  
  # tc ra observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('tc_ra')
    
    if(input$tc_ra){
      
      # add polygons
      proxy %>%
        addPolygons(data=tc_ra, group = 'tc_ra',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = F),
                    weight = 1, 
                    color = 'orange', 
                    fillColor = 'orange')
      
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
                    options = pathOptions(clickable = F),
                    group = 'tss') %>%
        addPolygons(data = tss_usa,
                    weight = .5,
                    color = 'grey',
                    fillColor = 'grey',
                    options = pathOptions(clickable = F),
                    group = 'tss')
      
    }
    
  })
  
  # US lobster observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('us_lobster')
    
    if(input$us_lobster){
      
      # add polygons
      proxy %>%
        addPolygons(data=us_lobster, group = 'us_lobster',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    popup = ~paste0(COMMNAME),
                    weight = 1, 
                    color = 'blue', 
                    fillColor = 'blue')
      
    }
    
  })
  
  # wind lease observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('wind_lease')
    
    if(input$wind_lease){
      
      # add polygons
      proxy %>%
        addPolygons(data=wind_lease, group = 'wind_lease',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    popup = ~paste(sep = "<br/>" ,
                                   "BOEM wind lease area",
                                   paste0("Name: ", info)),
                    weight = 1, 
                    color = 'brown', 
                    fillColor = 'brown')
      
    }
    
  })
  
  # wind lease observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('wind_planning')
    
    if(input$wind_planning){
      
      # add polygons
      proxy %>%
        addPolygons(data=wind_planning, group = 'wind_planning',
                    fill = T, 
                    fillOpacity = 0.25, 
                    stroke = T, 
                    popup = ~paste(sep = "<br/>" ,
                                   "BOEM wind planning area",
                                   paste0("Name: ", info)),
                    weight = 1, 
                    color = 'green', 
                    fillColor = 'green')
      
    }
    
  })
  
  # dma observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('dma')
    
    # add polygons
    # NOTE: previously this block was not gated on input$dma at all (it only
    # checked nrow(dma) > 0), so the "DMA" layer toggle checkbox never
    # actually controlled this layer's visibility - it was always redrawn.
    if(input$dma & nrow(dma_data()) > 0){
      proxy %>%
        addPolygons(data=dma_data(), group = 'dma',
                    fill = T, 
                    fillOpacity = 0.3, 
                    stroke = T, 
                    dashArray = c(5,5), 
                    options = pathOptions(clickable = T),
                    popup = ~paste(sep = "<br/>" ,
                                   "US Slow Zone",
                                   paste0(NAME),
                                   paste0("Type: ", TRIGGERTYPE),
                                   paste0("Expires: ", EXPDATE)),
                    weight = 1, 
                    color = '#ff9900', 
                    fillColor = '#ff9900')
    }
    
  })
  
  # sma observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('sma')
    
    if(input$sma & nrow(sma_data()) != 0){
      
      # add polygons
      proxy %>%
        addPolygons(data=sma_data(), group = 'sma',
                    fill = T, 
                    fillOpacity = 0.3, 
                    stroke = T, 
                    options = pathOptions(clickable = T),
                    popup = ~paste(sep = "<br/>" ,
                                   "US Seasonal Management Area",
                                   paste0(NAME),
                                   paste0("Active: ",STARTDATE, ' - ', ENDDATE)),
                    weight = 1, 
                    color = 'red', 
                    fillColor = 'red')
      
    }
    
  })
  
  # spd observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('spd')
    
    if(input$spd & nrow(spd) != 0){
      
      # add polygons
      proxy %>%
        addPolygons(data=spd, group = 'spd',
                    fill = T, 
                    fillOpacity = 0.3, 
                    stroke = T, 
                    options = pathOptions(clickable = T),
                    popup = ~paste(sep = "<br/>" ,
                                   "Proposed Right Whale Seasonal Speed Zone",
                                   paste0(NAME),
                                   paste0("Active: ",STARTDATE, ' - ', ENDDATE)),
                    weight = 1, 
                    color = 'darkgreen', 
                    fillColor = 'darkgreen')
      
    }
    
  })
  
  # alwtrp observer ------------------------------------------------------  
  
  observe(priority = 4, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('alwtrp')
    
    if(input$alwtrp){
      
      # add polygons
      proxy %>%
        addPolygons(data=alwtrp, group = 'alwtrp',
                    fill = T, 
                    fillOpacity = 0.3, 
                    stroke = T, 
                    options = pathOptions(clickable = T),
                    popup = ~paste(sep = "<br/>" ,
                                   "US fishery seasonal restricted area",
                                   paste0(ID),
                                   paste0('Active: ', ACTIVE)),
                    weight = 1, 
                    color = 'brown2', 
                    fillColor = 'brown2')
      
    }
    
  })
  
  # track observer ------------------------------------------------------  
  
  # observe(priority = 3, {
  observeEvent(input$tracks|input$go|input$go == 0, priority = 3, {
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('tracks')
    
    # tracks rendered via leafgl (Leaflet.glify) are WebGL layers, not
    # standard leaflet layers, so clearGroup('tracks') above does NOT remove
    # them - they have to be removed explicitly by layerId. Wrapped in
    # tryCatch since this errors harmlessly the first time the app loads
    # (nothing has been added with this layerId yet).
    tryCatch(removeGlPolylines(proxy, layerId = 'gltracks'), error = function(e) NULL)
    
    # tracks
    
    if(input$tracks & nrow(trk())<npts|input$password == password){
      
      # get color palette
      pal = colorpal_trk()
      
      ind = which(colnames(trk())==colorby_trk())
      
      # set up polyline plotting - sort within each id so points connect
      # in time order. A row with NA lon/lat is a deliberate "break" marker
      # (not a data error) - it's how a gap gets introduced into a single
      # track's line without needing a separate id, matching the old
      # addPolylines() behavior where an NA in the coordinate vector created
      # a visual gap. mark a new segment every time an NA row is hit within
      # an id, then drop the NA rows themselves (they're not real points) -
      # each segment becomes its own LINESTRING feature below, since leafgl
      # doesn't support MULTILINESTRING geometry, so a single id can now
      # produce more than one feature (sharing the same color/popup) when it
      # contains a break.
      # trk_sorted <- trk()[order(trk()$id, trk()$time), ]
      trk_sorted <- trk() %>%
        group_by(id) %>%
        mutate(.seg = cumsum(is.na(lon) | is.na(lat))) %>%
        ungroup()
      trk_sorted <- trk_sorted[!is.na(trk_sorted$lon) & !is.na(trk_sorted$lat), ]
      tracks.df <- split(trk_sorted, paste(trk_sorted$id, trk_sorted$.seg, sep = '__'))
      tracks.df <- tracks.df[vapply(tracks.df, nrow, integer(1)) >= 2]
      
      # NOTE: previously this issued ONE addPolylines() call per track id via
      # purrr::walk(), which for hundreds of tracks means hundreds of separate
      # proxy calls sent to the browser - each with real overhead. Building
      # one sf object with one LINESTRING feature per track (or per segment,
      # for tracks with a break) and drawing it in a single call (now via
      # leafgl's WebGL renderer, addGlPolylines) is both far fewer calls AND
      # WebGL-rendered, which is the main speedup for datasets with many/long
      # tracks.
      if(length(tracks.df) > 0){
        
        line_geoms <- lapply(tracks.df, function(d){
          sf::st_linestring(as.matrix(d[, c('lon','lat')]))
        })
        
        trk_ids    <- vapply(tracks.df, function(d) as.character(d$id[1]), character(1))
        first_vals <- vapply(tracks.df, function(d) as.character(d[[ind]][1]), character(1))
        
        lines_sf <- sf::st_sf(
          id = trk_ids,
          trk_color = pal(first_vals),
          trk_popup = paste0('Track ID: ', trk_ids),
          geometry = sf::st_sfc(line_geoms, crs = 4326)
        )
        
        proxy <- proxy %>%
          addGlPolylines(data = lines_sf,
                         layerId = 'gltracks',
                         group = 'tracks',
                         weight = 0.4,
                         opacity = 0.3,
                         color = lines_sf$trk_color,
                         popup = lines_sf$trk_popup,
                         hover = glify_hover_js)
      }
      
    }
    
  })
  
  # buoy observer ------------------------------------------------------  
  # split out from the track observer above so it can run at a lower
  # priority than possible/detected below - see the priority-ordering note
  # by the "latest observer" section for why.
  observeEvent(input$tracks|input$go|input$go == 0, priority = 0, {
    
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('buoys')
    
    if(input$tracks & nrow(trk())<npts|input$password == password){
      
      pal = colorpal_trk()
      ind = which(colnames(trk())==colorby_trk())
      
      # set up buoy plotting (first ping per buoy deployment). buoy
      # deployments are a small handful of points at most, so this stays on
      # the regular (non-WebGL) leaflet renderer - the batching fix from
      # before (single vectorized addCircleMarkers call) is enough here.
      # drop_na_coords() removes rows with missing/invalid lat or lon before
      # they ever reach addCircleMarkers() - a buoy's very first
      # transmission after deployment can land without a GPS fix yet, and
      # passing that straight to leaflet triggered a validateCoords()
      # warning (and, once that row was leaflet's only row, a follow-on
      # "no non-missing arguments to min" warning from trying to summarize
      # an now-empty cleaned dataset).
      buoy.df <- trk() %>%
        filter(platform == 'buoy') %>%
        drop_na_coords() %>%
        arrange(time) %>%
        group_by(id) %>%
        dplyr::slice(1) %>%
        ungroup()
      
      if(nrow(buoy.df) > 0){
        buoy_colors <- pal(as.character(buoy.df[[ind]]))
        buoy_popups <- paste0('Track ID: ', buoy.df$id)
        
        proxy %>%
          addCircleMarkers(data = buoy.df,
                           radius = 6, 
                           opacity = 1,
                           stroke = T, 
                           fill = T,
                           fillOpacity = 0,
                           weight = 2.5,
                           group = 'buoys', 
                           lng = ~lon, 
                           lat = ~lat, 
                           color = buoy_colors,
                           popup = buoy_popups)
      }
      
    }
    
  })
  
  # latest observer ------------------------------------------------------  
  # NOTE on layer order: on startup and after "Go", the default visual
  # stacking (bottom to top) should be polygons < tracks < observations <
  # icons (buoys/live positions). This is controlled purely by *when* each
  # observer's block runs and adds its layer to the map - later-added layers
  # draw on top of earlier ones - so priority is set high (runs first, ends
  # up at the bottom) for polygons and progressively lower (runs later, ends
  # up higher) for tracks, then observations, then icons. This intentionally
  # preserves the old/original behavior where toggling any individual layer
  # off and back on re-adds it last, putting it on top regardless of this
  # default order - only the STARTUP order is being controlled here.
  if(file.exists(lfile)){
    
    observe(priority = 0, {
      
      # define proxy
      proxy <- leafletProxy("map")
      proxy %>% clearGroup('latest')
      
      # tracks
      
      if(input$latest){
        
        # add icons for latest position of live dcs platforms
        # NOTE: zIndex raised from 350 to 450. At 350 this pane sat BELOW
        # leaflet's default overlayPane (400) - harmless when tracks were
        # plain SVG paths (which only intercept clicks exactly on the drawn
        # line), but leafgl's WebGL tracks now render to a full-viewport
        # <canvas> in that same overlayPane, and canvas elements capture
        # click events across their whole bounding box regardless of visual
        # transparency. That canvas was very likely swallowing clicks meant
        # for these icons before they ever reached the lower "lts" pane,
        # which is the most likely reason the popup stopped opening.
        proxy %>% 
          addMapPane("lts", zIndex = 450) %>%
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
  
  # shared popup builder for observation points (possible + definite) ------
  
  build_obs_popup <- function(d){
    paste(sep = "<br/>",
         paste0("Species: ", d$species),
         paste0("Score: ", d$score),
         paste0("Number: ", d$number),
         paste0("Calves: ", d$calves),
         paste0("Platform: ", d$platform),
         paste0("Name: ", d$name),
         paste0("Date: ", as.character(d$date)),
         paste0("Time: ", as.character(format(d$time, '%H:%M:%S UTC'))),
         paste0("Position: ", as.character(d$lat), ', ', as.character(d$lon)),
         paste0("Source: ", d$source))
  }
  
  # sf::st_as_sf() refuses to build point geometry from NA coordinates
  # (unlike the old addCircleMarkers(), which just silently skipped/rendered
  # nothing for those rows) - drop them first.
  drop_na_coords <- function(d){
    d[!is.na(d$lon) & !is.na(d$lat), ]
  }
  
  # shared leafgl hover-cursor callback --------------------------------------
  # passed to the "hover" argument of addGlPoints()/addGlPolylines() below
  # via their ... passthrough straight to Leaflet.glify's own JS. See the
  # onRender() note in output$map for why this approach (vs. the earlier,
  # unsuccessful Shiny-event attempt) should actually work. Targets the map
  # container directly by its known selector rather than assuming the exact
  # shape of the callback's own arguments (e/feature/xy), which isn't
  # something I can verify without a live browser - this way the fix only
  # depends on the callback firing at all, not on what it's passed.
  glify_hover_js <- htmlwidgets::JS("
    function(e, feature, xy) {
      document.querySelector('#map .leaflet-container').style.cursor = 'pointer';
    }
  ")
  
  # possible observer ------------------------------------------------------  
  
  observe(priority = 2,{
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('possible')
    
    # leafgl (WebGL) layers aren't tracked by clearGroup() above - they have
    # to be removed explicitly by layerId. Safe to call even before anything
    # has been added.
    tryCatch(removeGlPoints(proxy, layerId = 'glpossible'), error = function(e) NULL)
    
    pos_clean <- drop_na_coords(pos())
    
    if(input$possible & nrow(pos_clean) > 0){
      
      # set up color palette plotting
      pal <- colorpal_obs()
      
      # possible detections - rendered via leafgl's WebGL point layer
      # (addGlPoints) instead of leaflet's addCircleMarkers. Switching back
      # to this (after having reverted it once before) because the actual
      # trigger for slowness/crashes turned out to be large OBSERVATION
      # point counts (multi-species, multi-year selections), not just large
      # track counts - addCircleMarkers renders one DOM/SVG element per
      # point, which doesn't scale the way a single WebGL draw call does.
      pos_sf <- sf::st_as_sf(pos_clean, coords = c('lon','lat'), crs = 4326, remove = FALSE)
      
      addGlPoints(map = proxy, data = pos_sf, group = 'possible',
                 layerId = 'glpossible', pane = 'obsPane',
                 radius = 10, fillOpacity = 0.9,
                 fillColor = pal(pos_sf[[colorby_obs()]]),
                 popup = build_obs_popup(pos_sf),
                 hover = glify_hover_js)
    }
  })
  
  # definite observer ------------------------------------------------------  
  
  observe(priority = 1,{
    
    # define proxy
    proxy <- leafletProxy("map")
    proxy %>% clearGroup('detected')
    
    tryCatch(removeGlPoints(proxy, layerId = 'gldetected'), error = function(e) NULL)
    
    det_clean <- drop_na_coords(det())
    
    if(input$detected & nrow(det_clean) > 0){
      
      # set up color palette plotting
      pal <- colorpal_obs()
      
      # definite detections - see note above on addGlPoints
      det_sf <- sf::st_as_sf(det_clean, coords = c('lon','lat'), crs = 4326, remove = FALSE)
      
      addGlPoints(map = proxy, data = det_sf, group = 'detected',
                 layerId = 'gldetected', pane = 'obsPane',
                 radius = 10, fillOpacity = 0.9,
                 fillColor = pal(det_sf[[colorby_obs()]]),
                 popup = build_obs_popup(det_sf),
                 hover = glify_hover_js)
    }
  })
  
  # combined visible observations -----------------------------------------
  # shared by the legend observer and dInBounds() below so the
  # rbind(det(), pos()) combination (and the input$detected/input$possible
  # switch logic behind it) is computed once per invalidation instead of
  # twice.
  
  visibleObs <- reactive({
    if(input$detected & input$possible){
      rbind(det(), pos())
    } else if(input$detected & !input$possible){
      det()
    } else if(!input$detected & input$possible){
      pos()
    } else {
      NULL
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
    dat <- visibleObs()
    if(is.null(dat)){
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
  
  # map_bounds updates continuously while the user drags/zooms the map,
  # which used to trigger a full re-filter + re-render of the summary text
  # and bar graph on every intermediate frame of the drag. Debouncing it
  # means downstream reactives only recompute ~400ms after the user stops
  # moving the map.
  map_bounds_debounced <- reactive({ input$map_bounds }) %>% debounce(400)
  
  # determine tracks in map bounds
  tInBounds <- reactive({
    if (is.null(map_bounds_debounced()))
      return(trk()[FALSE,])
    bounds <- map_bounds_debounced()
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(trk(),
           lat >= latRng[1] & lat <= latRng[2] &
             lon >= lngRng[1] & lon <= lngRng[2])
  })
  
  # determine detections in map bounds
  dInBounds <- reactive({
    
    # determine which dataset to use based on display switches
    # (shared with the legend observer via visibleObs(), see above)
    dat <- visibleObs()
    if(is.null(dat)){
      dat = data.frame()
      return(dat[FALSE,])
    }
    
    # catch error if no data is displayed
    if (is.null(map_bounds_debounced())){
      return(dat[FALSE,])
    }
    
    # define map bounds
    bounds <- map_bounds_debounced()
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    # subset of data in bounds
    subset(dat,
           lat >= latRng[1] & lat <= latRng[2] &
             lon >= lngRng[1] & lon <= lngRng[2])
  })
  
  # create text summary
  output$summary <- renderUI({
    if(nrow(dInBounds())==0){
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
      
      # NOTE: these were previously built with ifelse(input$possible, a<-.., b<-0),
      # which is a real bug - ifelse() evaluates BOTH the "yes" and "no"
      # arguments as a side effect of its internal vectorized subsetting, so
      # both assignments always ran and the variable always ended up holding
      # whichever assignment executed last (the "0" branch), regardless of
      # input$possible. Using ordinary if/else fixes this.
      if(input$possible){
        t <- nrow(dInBounds()[dInBounds()$score=='possible visual',])
      } else {
        t <- 0
      }
      
      str4 <- paste0('<strong>Number of possible sighting events</strong>: ', t)
      
      if(input$possible){
        u <- sum(dInBounds()$number[dInBounds()$score=='possible visual'], na.rm = T)
      } else {
        u <- 0
      }
      
      str5 <- paste0('<strong>Number of whales possibly sighted</strong>: ', u)
      
      str6 <- paste0('<strong>Number of definite detections</strong>: ', 
                     nrow(dInBounds()[dInBounds()$score=='definite acoustic',]))
      
      if(input$possible){
        v <- nrow(dInBounds()[dInBounds()$score=='possible acoustic',])
      } else {
        v <- 0
      }
      
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
    
    # conditionally remove possibles for plotting
    if(!input$possible){
      obs = obs[obs$score!='possible acoustic' & obs$score!='possible visual',]
    }
    
    # avoid error if no data selected or in map view
    if(nrow(obs)==0){
      return(NULL)
    }
    
    # define input tracks
    if(input$plotInBounds){
      # use only data within map bounds
      tracks = tInBounds()
    } else {
      # use all input data
      tracks = trk()  
    }
    
    # make categories for facet plotting
    obs$cat = ''
    obs$cat[obs$score == 'definite visual' | obs$score == 'possible visual'] = 'Sighting events per day'
    obs$cat[obs$score == 'definite acoustic' | obs$score == 'possible acoustic'] = 'Acoustic detection events per day'
    
    # determine days with trackline effort
    vis_effort = unique(tracks$yday[tracks$platform %in% visual_platforms])
    aco_effort = unique(tracks$yday[tracks$platform %in% acoustic_platforms])
    tot_effort = c(vis_effort, aco_effort)
    
    # configure effort geometry for plotting
    if(length(tot_effort)!=0){
      eff = data.frame('yday' = tot_effort,
                       'cat' = c(rep('Sighting events per day',length(vis_effort)), 
                                 rep('Acoustic detection events per day',length(aco_effort))),
                       'y' = -1)
      geom_effort = geom_point(data = eff, aes(x = yday, y=y), pch=45, cex = 3, col = 'blue')
    } else {
      geom_effort = NULL
    }
    
    # determine number of factor levels to color
    ncol = length(unique(obs[,which(colnames(obs)==colorby_obs())]))
    
    # choose palette for discrete scale
    cols = get_palette(pal = pal_obs(), n = ncol)
    
    # define min and max yday
    min_yday = isolate(min(yday(dates())))
    max_yday = isolate(max(yday(dates())))
    
    if(colorby_obs() %in% c('number', 'calves', 'lat','lon', 'year')){
      
      # replace all sightings/detections with '1' to facilitate stacked plotting
      obs$counter = 1
      
      # convert to factor for discrete colouring
      obs[,colorby_obs()] = as.factor(obs[,colorby_obs()])
      
      # define palette for discrete scale
      fillcols = scale_fill_manual(values = cols, name = colorby_obs(), 
                                   na.value = 'darkslategrey')
      
      # build plot
      g = ggplot(obs, aes(x = yday, y = counter))+
        geom_col(na.rm = T, aes(fill = .data[[colorby_obs()]]))+
        labs(x = '', y = '')+
        fillcols+
        facet_wrap(~cat, scales="free_y", nrow = 2)+
        scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"), 
                           breaks = seq(from = min_yday, to = max_yday, length.out = 6))+
        aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))+
        geom_effort+
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
      
      # count score by day, variable and category
      cnt = obs %>% group_by(cat, (!!as.name(colorby_obs())), yday) %>%
        count()
      
      # build plot
      g = ggplot(cnt, aes(x = yday))+
        geom_col(na.rm = T, aes(fill = .data[[colorby_obs()]], y = n))+
        labs(x = '', y = '')+
        fillcols+
        facet_wrap(~cat, scales="free_y", nrow = 2)+
        scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"), 
                           breaks = seq(from = min_yday, to = max_yday, length.out = 6))+
        aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))+
        geom_effort+
        expand_limits(x = c(min_yday, max_yday))
      
    }
    
    # build interactive plot
    # ggplotly() (via ggplot_build()) computes each facet's own axis range
    # internally, since facet_wrap(scales = "free_y") gives each facet an
    # independent scale. If the "plot in bounds" view has zero rows for one
    # facet (e.g. no acoustic detections currently in the visible map area
    # while there are sightings), that facet's internal range calculation
    # calls min()/max() on nothing - this is what's actually producing the
    # "no non-missing arguments" warning when toggling input$plotInBounds,
    # not any of our own code (all of our own min()/max() calls above are
    # already guarded against empty data). Scoping suppressWarnings() to
    # just this call keeps it from hiding warnings anywhere else in the app.
    gg = suppressWarnings(
      ggplotly(g, dynamicTicks = F, tooltip = c("text", "count", "fill")) %>%
        layout(margin=list(r=120, l=70, t=40, b=70), showlegend = input$legend)
    )
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
