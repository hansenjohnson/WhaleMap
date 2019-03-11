library(rhandsontable)
library(shiny)
library(shinydashboard)
library(leaflet)
library(leaflet.extras)

header <-  dashboardHeader(title = 'HotMap')

body <- dashboardBody(
  fluidRow(
    column(width = 3,
           tabBox(title = 'Coordinate editor', width = NULL,
                  
                  tabPanel(title = 'tst',
                           helpText('Drop new points with ',icon("map-marker", lib = 'glyphicon'), 
                                    '. Edit points with ', icon("edit", lib = 'glyphicon'),
                                    ' or via the table below. Remove one or all points with', 
                                    icon("trash", lib = 'glyphicon')),
                           strong('Coordinate list'),
                           rHandsontableOutput("hot", height = 250),
                           strong('Round coordinates'),
                           helpText('Choose number of decimal places'),
                           numericInput('dig', label = NULL, value = 1,
                                        min = 0, max = 6, step=1, width = 50),
                           actionButton('round', 'Round'),
                           radioButtons('shp', label = 'Connection between points', 
                                        choices = c('None', 'Line', 'Polygon'), 
                                        selected = 'None', inline = F),
                           strong('Save coordinates'), br(),
                           downloadButton("downloadData", "Save")
                  )
           )
    ),
    column(width = 9,
           box(width = NULL, solidHeader = T,collapsible = T, 
               title = 'Map', 
               status = 'primary',
               
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
  output$map = renderLeaflet({
    leaflet() %>% 
      addTiles() %>% setView(lng = -65, lat = 45, zoom = 5) %>%
      addDrawToolbar(position = "topleft",
                     polylineOptions = drawPolylineOptions(metric = TRUE),
                     polygonOptions = F,
                     circleOptions = F,
                     rectangleOptions = F,
                     markerOptions = F, 
                     editOptions = editToolbarOptions(),
                     targetGroup = 'grp',
                     singleFeature = T
      )
  })
  
  observeEvent(input$map_draw_all_features,{
    
    # extract lat lons of drawn objects
    f = input$map_draw_all_features
    ll = sapply(f$features, FUN = function(x) x$geometry$coordinates)
    DF = do.call(rbind, ll)
    colnames(DF) = c('lng', 'lat')
    
    # construct table
    output$hot = renderRHandsontable({
      rhandsontable(DF) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
      
    })
  })
  
  observeEvent(input$round,{
    DF = hot_to_r(input$hot)
    DF = round(DF, digits = input$dig)
    
    output$hot = renderRHandsontable({
      rhandsontable(DF) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
    })
  })
  
  # # update map after editing coordinates
  # observe({
  #   if (is.null(input$hot))
  #     return()
  #   
  #   print(hot_to_r(input$hot))
  #   # read in values from table
  #   DF = hot_to_r(input$hot)
  #   
  #   # catch error for blank DF (e.g. after deleting all points)
  #   if(is.null(DF$lng)){
  #     leafletProxy("map") %>% clearGroup('add')
  #     return()
  #   }
  #   
  #   # replace old positions on map
  #   proxy = leafletProxy("map")
  #   
  #   proxy %>%
  #     removeDrawToolbar(clearFeatures=TRUE) %>%
  #     addDrawToolbar(position = "topleft",
  #                    polylineOptions = drawPolylineOptions(metric = T),
  #                    polygonOptions = F,
  #                    circleOptions = F,
  #                    rectangleOptions = F,
  #                    markerOptions = F, 
  #                    editOptions = editToolbarOptions(),
  #                    targetGroup = 'grp',
  #                    singleFeature = T
  #     ) %>%
  #     addMarkers(data = DF, lng = ~lng, lat = ~lat, group = 'grp', label = ~paste0(lat, ', ', lng))
  #   
  #   if(input$shp == 'None'){
  #     proxy %>% 
  #       clearGroup('add')
  #   } else if (input$shp == 'Line'){
  #     proxy %>% 
  #       clearGroup('add')%>%
  #       addPolylines(data = DF, lng = ~lng, lat = ~lat, group = 'add')
  #   }else if (input$shp == 'Polygon'){
  #     proxy %>% 
  #       clearGroup('add')%>%
  #       addPolygons(data = DF, lng = ~lng, lat = ~lat, group = 'add')
  #   }
  # })
  
  # download csv
  output$downloadData <- downloadHandler(
    filename = function() {
      "WhaleMap.csv"
    },
    content = function(file) {
      write.csv(hot_to_r(input$hot), file, row.names = FALSE)
    }
  )
  
}



shinyApp(ui, server)
