# https://github.com/r-spatial/mapedit/issues/61
library(shiny)
library(leaflet)
library(leaflet.extras)
library(mapedit)
library(mapview)

ui <- tagList(
  editModUI("editor"),
  actionButton("clear", "Clear Points"),
  actionButton("start", "Start Drawing"),
  actionButton("end", "Finish Drawing")
)

server <- function(input, output, session) {
  # to use the namespace that we gave
  ns <- NS("editor")
  
  base_map <- leaflet() %>% 
    addTiles() %>% 
    addFeatures(breweries)
  drawn <- callModule(editMod, "editor", base_map)
  # start with drawing off
  leafletProxy(ns("map")) %>%
    removeDrawToolbar()
  
  observe({print(drawn())})
  
  observeEvent(input$clear, {
    leafletProxy(ns("map")) %>%
      clearMarkers()
  })
  
  observeEvent(input$start, {
    leafletProxy(ns("map")) %>%
      addDrawToolbar(editOptions = editToolbarOptions())
  })
  
  observeEvent(input$end, {
    leafletProxy(ns("map")) %>%
      removeDrawToolbar(clearFeatures = TRUE)
  })
}

shinyApp(ui, server)