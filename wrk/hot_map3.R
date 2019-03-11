library(rhandsontable)
library(leaflet)
library(shiny)
library(shinydashboard)
library(leaflet.extras)
# We need latest leaflet package from Github, as CRAN package is too old.
# devtools::install_github('rstudio/leaflet')
# devtools::install_github('bhaskarvk/leaflet.extras')

# js src ------------------------------------------------------------------

scr1 <- tags$script(HTML(
  "
  Shiny.addCustomMessageHandler(
  'removeleaflet',
  function(x){
  console.log('deleting',x)
  // get leaflet map
  var map = HTMLWidgets.find('#' + x.elid).getMap();
  // remove
  map.removeLayer(map._layers[x.layerid])
  })
  "
))


scr2 <- tags$script(HTML(
  "
  Shiny.addCustomMessageHandler(
  'addleaflet',
  function(x){
  console.log('adding',x)
  // get leaflet map
  var map = HTMLWidgets.find('#' + x.elid).getMap();
  
  // add marker
  var marker = L.marker([x.lat, x.lng]);
  marker.editing.enable();
  map.addLayer(marker);
  })
  "
))

# app ---------------------------------------------------------------------

header <-  dashboardHeader(title = 'HotMap')

body <- dashboardBody(
  fluidRow(
    column(width = 3, 
           box(width = NULL, title = 'Inputs',collapsible = T, collapsed = F,
               rHandsontableOutput("hot", height = 200),
               actionButton('round', 'Round?'),
               numericInput('dig', label = NULL, value = 1, 
                            min = 0, max = 6, step=1, width = 50),
               actionButton('clear', 'Clear'),br(),
               downloadButton("downloadData", "Save")
           )
    ),
    column(width = 9,
           box(width = NULL, title = 'Map',
               leafletOutput("map")
           )
    )
  ),
  tagList(scr1, scr2)
)

ui = dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)

server = function(input, output, session) {
  
  # build map
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% setView(lng = -65, lat = 45, zoom = 5) %>%
      addMarkers(lng = -65, lat = 45, group = 'ui') %>%
      addDrawToolbar(targetGroup = 'ui',
                     position = c("topleft"),
                     polylineOptions = F,
                     polygonOptions = F,
                     circleOptions = F,
                     rectangleOptions = F,
                     markerOptions = drawMarkerOptions(repeatMode = T), 
                     editOptions = editToolbarOptions(),
                     singleFeature = F
      )
  })
  
  observeEvent(input$map_draw_all_features,{
    
    # extract layer ids of drawn objects
    drawnshapes <<- lapply(
      input$map_draw_all_features$features,
      function(ftr) {
        ftr$properties$`_leaflet_id`
      }
    )
    
    str(drawnshapes)
    
    ll = list(c(-65,45), c(-67, 44))
    
      # add new shapes
      lapply(
        ll,
        function(x) {
          session$sendCustomMessage(
            "addleaflet",
            list(elid="map", lat=x[2], lng=x[1])
          )
        }
      )
    
    # extract lat lons of drawn objects
    f = input$map_draw_all_features
    lng = sapply(f$features, FUN = function(x) x$geometry$coordinates[[1]])
    lat = sapply(f$features, FUN = function(x) x$geometry$coordinates[[2]])
    DF = data.frame(lng, lat)
    DF = DF[!duplicated(DF),]
    str(DF)
    
    # construct table
    output$hot = renderRHandsontable({
      rhandsontable(DF, rowHeaders = NULL) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
    
    })
    
    # update map
    # observe({
    #   if (is.null(input$hot))
    #     return()
    #   
    #   DF = hot_to_r(input$hot)
    #   
    #   str(DF)
    #   # clear drawn shapes
    #   lapply(
    #     drawnshapes,
    #     function(todelete) {
    #       session$sendCustomMessage(
    #         "removeleaflet",
    #         list(elid="map", layerid=todelete)
    #       )
    #     }
    #   )
    #   
    #   str(drawnshapes)
    #   leafletProxy("map") %>%
    #     clearGroup('ui')%>%
    #     addMarkers(data = DF, lng = ~lng, lat = ~lat, group = 'ui')
    # })
    
    
  })
  
  # observeEvent(input$map_draw_all_features,{
  #   if (is.null(input$hot)){
  #     # DF = NULL
  #     return()
  #   } else {
  #     DF = hot_to_r(input$hot)
  #   }
  #   
  #   print(DF)
  #   
  #   # clear drawn shapes
  #   lapply(
  #     drawnshapes,
  #     function(todelete) {
  #       session$sendCustomMessage(
  #         "removeleaflet",
  #         list(elid="map", layerid=todelete)
  #       )
  #     }
  #   )
  # 
  #   leafletProxy("map") %>%
  #     clearGroup('ui')
  #     addMarkers(DF$lng, DF$lat, group = 'ui')
  # })
  # 
  # clear map
  # observeEvent(input$clear,{
  # 
  #   # clear drawn shapes
  #   lapply(
  #     drawnshapes,
  #     function(todelete) {
  #       session$sendCustomMessage(
  #         "removeleaflet",
  #         list(elid="map", layerid=todelete)
  #       )
  #     }
  #   )
  # 
  #   # clear table
  #   DF = hot_to_r(input$hot)
  #   DF = DF[0,]
  # 
  #   output$hot = renderRHandsontable({
  #     rhandsontable(DF, rowHeaders = NULL) %>%
  #       hot_table(highlightCol = TRUE, highlightRow = TRUE)
  # 
  #   })
  # })
  
  # # round table and update map
  # observeEvent(input$round,{
  #   DF = hot_to_r(input$hot)
  #   DF = round(DF, digits = input$dig)
  #   
  #   output$hot = renderRHandsontable({
  #     rhandsontable(DF, rowHeaders = NULL) %>%
  #       hot_table(highlightCol = TRUE, highlightRow = TRUE)
  #   })
  #   
  #   # clear drawn shapes
  #   lapply(
  #     drawnshapes,
  #     function(todelete) {
  #       session$sendCustomMessage(
  #         "removeleaflet",
  #         list(elid="map", layerid=todelete)
  #       )
  #     }
  #   )
  #   
  #   leafletProxy("map") %>%
  #     clearGroup('ui')%>%
  #     addMarkers(data = DF, lng = ~lng, lat = ~lat, group = 'ui')
  # })
  
}

shinyApp(ui, server)
