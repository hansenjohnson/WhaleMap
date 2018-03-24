# https://github.com/bhaskarvk/leaflet.extras/issues/96
# from: timelyportfolio

library(leaflet)
library(leaflet.extras)
library(mapview) # for easier base map

lf = mapview()@map %>%
  addDrawToolbar()

# this will be tricky referring to both R leaflet and JS leaflet
#  I will use rleaflet and jsleaflet to distinguish

# Layer manager and methods
#  rleaflet has a very handy helper called LayerManager
#  https://github.com/rstudio/leaflet/blob/master/javascript/src/layer-manager.js
#  that provides the foundation for the methods made available to R and Shiny
#  https://github.com/rstudio/leaflet/blob/master/javascript/src/methods.js

# Leaflet.draw not in LayerManager
#  since Leaflet.draw new shapes are not added through R, the shapes are
#  not added to the LayerManager.

# We will be on our own with our newly drawn Leaflet.Draw shapes.

# Now for some code.

library(shiny)

ui <- leafletOutput("ourmap")

server <- function(input, output, session) {
  output$ourmap <- renderLeaflet({lf})
  
  # keep track of newly drawn shapes
  drawnshapes <- list()
  
  # we are fortunate here since we get an event
  #   draw_all_features
  observeEvent(
    input$ourmap_draw_all_features,
    {
      drawnshapes <- lapply(
        input$ourmap_draw_all_features$features,
        function(ftr) {
          ftr$properties$`_leaflet_id`
        }
      )
      # seeing is believing
      str(drawnshapes)
    }
  )
}

shinyApp(ui,server)


# It seems that step 1 is complete.  We need to know the leaflet
#  stamp or id to be able to remove.  For our next bit of code
#  we will need some JavaScript.

scr <- tags$script(HTML(
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

# then our new app can do something like this

ui <- tagList(
  scr,
  leafletOutput("ourmap"),
  actionButton("deletebtn", "remove drawn")
)

server <- function(input, output, session) {
  output$ourmap <- renderLeaflet({lf})
  
  # keep track of newly drawn shapes
  drawnshapes <- list()
  
  # we are fortunate here since we get an event
  #   draw_all_features
  observeEvent(
    input$ourmap_draw_all_features,
    {
      drawnshapes <<- lapply(
        input$ourmap_draw_all_features$features,
        function(ftr) {
          ftr$properties$`_leaflet_id`
        }
      )
      # seeing is believing
      str(drawnshapes)
    }
  )
  
  # observe our simple little button to remove
  observeEvent(
    input$deletebtn,
    {
      lapply(
        drawnshapes,
        function(todelete) {
          session$sendCustomMessage(
            "removeleaflet",
            list(elid="ourmap", layerid=todelete)
          )
        }
      )
      print(drawnshapes)
    }
  )
}

shinyApp(ui,server)