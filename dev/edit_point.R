library(shiny)
library(leaflet)
library(RColorBrewer)

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
  numericInput("ilat", label = 'Latitude:', value = 1),
  numericInput("ilon", label = 'Longitude:', value = 1),
  actionButton("go", label = 'Plot'),
  actionButton("clear", label = 'Clear'))
)

server <- function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet(quakes) %>% addTiles() %>% setView(1,1, zoom = 5) %>%
      addDrawToolbar(
        polygonOptions = drawPolygonOptions(showArea = T, metric = TRUE,
                           shapeOptions = drawShapeOptions(), repeatMode = FALSE),
        rectangleOptions = drawRectangleOptions(showArea = F, metric = TRUE,
                             shapeOptions = drawShapeOptions(), repeatMode = FALSE),
        markerOptions = drawMarkerOptions(markerIcon = NULL, zIndexOffset = 2000,
                                          repeatMode = T),
        editOptions = editToolbarOptions(edit=TRUE)
        )
  })
  
  # observeEvent(input$map_click,{
  #   c = input$map_click
  #   if(!is.null(c)){
  #   proxy <- leafletProxy("map")
  #   proxy %>% addCircleMarkers(data = c, lng = ~lng, lat = ~lat, popup = ~paste0(lat, ', ', lng))
  #   }
  # })
  
  observeEvent(input$go,{
    proxy <- leafletProxy("map")
    proxy %>% addMarkers(lng = input$ilon, lat = input$ilat, group = 'ui',
                               markerOptions(clickable = TRUE, draggable = FALSE)
                               # popup = paste0(input$ilat, ', ', input$ilon)
                         )
  })
  
  observeEvent(input$clear,{
    proxy <- leafletProxy("map")
    proxy %>% clearGroup(group = 'ui')
  })
  
}

shinyApp(ui, server)