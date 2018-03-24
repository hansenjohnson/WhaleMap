library(rhandsontable)
library(leaflet)
library(shiny)
library(shinydashboard)
library(leaflet.extras)

# app ---------------------------------------------------------------------

header <-  dashboardHeader(title = 'HotMap')

body <- dashboardBody(
  fluidRow(
    column(width = 3, 
           box(width = NULL, title = 'Inputs',collapsible = T, collapsed = F,
               rHandsontableOutput("hot", height = 200),
               downloadButton("downloadData", "Save")
           )
    ),
    column(width = 9,
           box(width = NULL, title = 'Map',
               leafletOutput("map")
           )
    )
  )
)

ui = dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)

server = function(input, output, session) {
  
  # build map
  MyMap <- reactive({
    return(
      leaflet() %>% 
        addTiles() %>% setView(lng = -65, lat = 45, zoom = 5) %>%
        addMarkers(lng = -65, lat = 45, group = 'grp') %>%
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
    )
  })
    
  output$map <- renderLeaflet({
    MyMap()
  })
  
  # all
  observeEvent(input$map_draw_all_features,{
    
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
    
    output$mymap <- renderLeaflet({
        MyMap() %>% addCircleMarkers(DF$lng, DF$lat, group = 'grp')
    })
    
  })
}

shinyApp(ui, server)
