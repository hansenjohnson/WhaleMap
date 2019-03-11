# rhandsontable
library(rhandsontable)
library(leaflet)

# read in data
df = readRDS('../data/processed/mpa.rds')
# df = data.frame(lat = NA, lon = NA)

ui = fluidPage(
  titlePanel("test"),
  fluidRow(
    column(width = 6,
           rHandsontableOutput("hot")
    ),
    column(width = 6,
           actionButton('add', label = 'Add points'),
           actionButton('edit', label = 'Edit points'),
           actionButton('clear', label = 'Clear points'),
           leafletOutput("map")
    )
  )
)

server = function(input, output, session) {
  
  # build map
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% setView(lng = -65, lat = 45, zoom = 5)
  })
  
  # initialize reactive values
  val <- reactiveValues(data = NULL)
  mouse <- reactiveValues(click=NULL)
  
  observeEvent(input$map_click,
               {mouse$click <- input$map_click})
  
  observeEvent(input$add, {
    
    mouse$click <- NULL
    
    # click for locations
    observeEvent(input$map_click,{
      
      if(!is.null(mouse$click)){
        proxy <- leafletProxy("map")
        proxy %>% addMarkers(data = mouse$click, lng = ~lng, lat = ~lat, 
                             popup = ~paste0(lat, ', ', lng), 
                             group = 'ui')
        
        isolate({
          # add new points to data
          val$data <- rbind.data.frame(val$data, 
                                       cbind(lng = mouse$click$lng, lat = mouse$click$lat))
        })
        
        print(val$data)
      }
    })
  })
  
  # clear points
  observeEvent(input$clear, {
    proxy <- leafletProxy("map")
    proxy %>% clearGroup(group = 'ui')
  })
  
  # edit points
  observeEvent(input$edit,{
    
    output$hot = renderRHandsontable({
      if (!is.null(input$hot)) {
        DF = hot_to_r(input$hot)
      } else {
        DF = val$data
      }
      
      rhandsontable(DF, height = 300) %>%
        hot_table(highlightCol = TRUE, highlightRow = TRUE)
    })
    
    observe({
      if (!is.null(input$hot)) {
        DF = hot_to_r(input$hot)
      } else {
        DF = val$data
      }
      
      leafletProxy("map") %>%
        clearMarkers()%>%
        addMarkers(data = DF, lng = ~lng, lat = ~lat, group = 'ui')
    })
  })
}

shinyApp(ui, server)
