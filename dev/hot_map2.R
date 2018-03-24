library(rhandsontable)
library(leaflet)
library(shiny)
library(shinydashboard)

header <-  dashboardHeader(title = 'HotMap')

body <- dashboardBody(
  fluidRow(
    column(width = 3, 
           box(width = NULL, title = 'Inputs',collapsible = T, collapsed = F,
               rHandsontableOutput("hot", height = 200),
               actionButton('round', 'Round?'),
               numericInput('dig', label = NULL, value = 1, 
                            min = 0, max = 6, step=1, width = 50),
               actionButton('line', 'Plot line'),br(),
               actionButton('poly', 'Plot polygon'),br(),
               actionButton('clear', 'Clear'),br(),
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
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% setView(lng = -65, lat = 45, zoom = 5)
  })
  
  # click for locations, and update the map and table on each click
  observeEvent(input$map_click,{
    if (is.null(input$hot)){
      DF = NULL
    } else {
      DF = hot_to_r(input$hot)
    }
    
    # add new points to data frame
    DF <- rbind.data.frame(DF, cbind(lng = input$map_click$lng, lat = input$map_click$lat))
    
    # build table
    output$hot = renderRHandsontable({
      rhandsontable(DF, rowHeaders = NULL) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
    })
    
    # update map
    observe({
      if (is.null(input$hot))
        return()
      
      DF = hot_to_r(input$hot)
      
      leafletProxy("map") %>%
        clearGroup('ui')%>%
        addMarkers(data = DF, lng = ~lng, lat = ~lat, group = 'ui')
    })

  })
  
  # clear map and table
  observeEvent(input$clear,{
    leafletProxy("map") %>%
      clearGroup('ui')
    
    DF = hot_to_r(input$hot)
    DF = DF[0,]
    
    output$hot = renderRHandsontable({
      rhandsontable(DF, rowHeaders = NULL) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
    })
  })
  
  # round table and update map
  observeEvent(input$round,{
    DF = hot_to_r(input$hot)
    DF = round(DF, digits = input$dig)
    
    output$hot = renderRHandsontable({
      rhandsontable(DF, rowHeaders = NULL) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
    })
    
    leafletProxy("map") %>%
      clearGroup('ui')%>%
      addMarkers(data = DF, lng = ~lng, lat = ~lat, group = 'ui')
  })
  
  # plot as line
  observeEvent(input$line,{
    DF = hot_to_r(input$hot)
    
    leafletProxy("map") %>%
      clearGroup('ui')%>%
      addPolylines(data = DF, lng = ~lng, lat = ~lat, group = 'ui')
  })
  
  # plot as polygon
  observeEvent(input$poly,{
    DF = hot_to_r(input$hot)
    
    leafletProxy("map") %>%
      clearGroup('ui')%>%
      addPolygons(data = DF, lng = ~lng, lat = ~lat, group = 'ui')
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
}

shinyApp(ui, server)
