library(leaflet)
library(leaflet.extras)
library(shiny)

ui <- leafletOutput("leafmap")

server <- function(input, output, session) {
  output$leafmap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -65, lat = 45, zoom = 5) %>%
      addDrawToolbar(targetLayerId = NULL, targetGroup = 'ui',
                     position = c("topleft"),
                     polylineOptions = drawPolylineOptions(),
                     polygonOptions = drawPolygonOptions(),
                     circleOptions = F,
                     rectangleOptions = F,
                     markerOptions = drawMarkerOptions(repeatMode = T), 
                     editOptions = editToolbarOptions(),
                     singleFeature = F
      )
  })
  
  observeEvent(input$leafmap_draw_all_features,{
    print("All Features")
    print(input$leafmap_draw_all_features)
    print("Start Editing")
    print(input$leafmap_draw_editstart)
    print("Stop Editing")
    print(input$leafmap_draw_editstop)
  })
  
  
  
  # # Start of Drawing
  # observeEvent(input$leafmap_draw_start,{
  #   print("Start of drawing")
  #   print(input$leafmap_draw_start)
  # })
  # 
  # # Stop of Drawing
  # observeEvent(input$leafmap_draw_stop,{
  #   print("Stopped drawing")
  #   print(input$leafmap_draw_stop)
  # })
  # 
  # # New Feature
  # observeEvent(input$leafmap_draw_new_feature,{
  #   print("New Feature")
  #   print(input$leafmap_draw_new_feature)
  # })
  # 
  # # Edited Features
  # observeEvent(input$leafmap_draw_edited_features,{
  #   print("Edited Features")
  #   print(input$leafmap_draw_edited_features)
  # })
  # 
  # # Edited Features
  # observeEvent(input$leafmap_draw_editstart,{
  #   print("Start Editing")
  #   print(input$leafmap_draw_editstart)
  # })
  # 
  # # Deleted features
  # observeEvent(input$leafmap_draw_deleted_features,{
  #   print("Deleted Features")
  #   print(input$leafmap_draw_deleted_features)
  # })
  # 
  # # We also listen for draw_all_features which is called anytime
  # # features are created/edited/deleted from the map
  # observeEvent(input$leafmap_draw_all_features,{
  #   print("All Features")
  #   print(input$leafmap_draw_all_features)
  # })
}

shinyApp(ui, server)