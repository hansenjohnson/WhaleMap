library(shiny)
library(leaflet)
library(ggmap)

server <- function(input, output) {
  
  output$map <- renderLeaflet({
    
    # Get latitude and longitude
    if(input$target_zone=="Ex: Bamako"){
      ZOOM=2
      LAT=0
      LONG=0
    }else{
      target_pos=geocode(input$target_zone)
      LAT=target_pos$lat
      LONG=target_pos$lon
      ZOOM=12
    }
    
    # Plot it!
    leaflet() %>% 
      setView(lng=LONG, lat=LAT, zoom=ZOOM ) %>%
      addProviderTiles("Esri.WorldImagery")
  })
}


ui <- fluidPage(
  br(),
  leafletOutput("map", height="600px"),
  absolutePanel(top=20, left=70, textInput("target_zone", "" , "Ex: Bamako")),
  br()
)

shinyApp(ui = ui, server = server)