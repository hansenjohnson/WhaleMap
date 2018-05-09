# ui.R
# WhaleMap - a Shiny app for visualizing whale survey data

# setup -------------------------------------------------------------------

library(shiny)
library(leaflet)
library(rgdal)
library(htmltools)
library(htmlwidgets)
library(maptools)
library(lubridate)
library(oce)
library(plotly)
library(shinydashboard)
library(rhandsontable)
# library(shinyjqui)
#library(shinycssloaders)

# user input --------------------------------------------------------------

years = c('2014', '2015', '2016', '2017')
species = c('right', 'sei', 'fin', 'humpback')

# header ----------------------------------------------------------------------

header <-  dashboardHeader(title = 'WhaleMap',
                           
                           # data
                           dropdownMenu(
                             type = "notifications",
                             icon = icon('info-sign', lib = 'glyphicon'),
                             badgeStatus = NULL,
                             headerText = "",
                             notificationItem("Help",
                                              icon = icon('question-sign', lib = 'glyphicon'),
                                              href = "http://leviathan.ocean.dal.ca/leviathan_docs/WhaleMap-help.html"),
                             notificationItem("Data details",
                                              icon = icon('signal', lib = 'glyphicon'),
                                              href = "http://leviathan.ocean.dal.ca/leviathan_docs/WhaleMap-data.html"),
                             notificationItem("Code",
                                              icon = icon('console', lib = 'glyphicon'),
                                              href = "https://github.com/hansenjohnson/WhaleMap"),
                             notificationItem("View/Report Issues",
                                              icon = icon('remove-sign', lib = 'glyphicon'),
                                              href = "https://github.com/hansenjohnson/WhaleMap/issues")
                           ),
                           
                           # leviathan
                           dropdownMenu(
                             type = "notifications",
                             icon = 'leviathan.ocean.dal.ca',
                             badgeStatus = NULL,
                             headerText = "",
                             notificationItem("Home",
                                              icon = icon("home"),
                                              href = "http://leviathan.ocean.dal.ca")
                             # notificationItem("Live Glider",
                             #                  icon = icon("plane", lib = 'glyphicon'),
                             #                  href = "http://leviathan.ocean.dal.ca/live_glider/")
                             
                           )
)

jscode <- '
$(function() {
  var $els = $("[data-proxy-click]");
  $.each(
    $els,
    function(idx, el) {
      var $el = $(el);
      var $proxy = $("#" + $el.data("proxyClick"));
      $el.keydown(function (e) {
        if ((e.keyCode || e.which) == 13) {
          $proxy.click();
        }
      });
    }
  );
});
'

# body --------------------------------------------------------------------

body <- dashboardBody(
  
  fluidRow(
    tags$head(tags$script(HTML(jscode))),
    
    # development warning message
    column(width = 12, align = "center",
           box(width = NULL, solidHeader = T,collapsible = F, collapsed = T,
               status = 'danger', background = 'red',
               
               # warning text
               h4('Warning: WhaleMap is under active development')
           )
    ),
    
    # editor tab ----------------------------------------------------------
    column(width = 3,
           
           tabBox(title = 'Editor', width = NULL,
                  
                  # Select Data    
                  tabPanel(title = 'Data',
                           
                           # choose year input
                           radioButtons("yearType", label = 'Choose year(s):', 
                                        choiceNames = c('Specific year(s):','Range of years:'),
                                        choiceValues = c('select', 'range')),
                           
                           uiOutput("yearChoice"),
                           
                           hr(),
                           
                           uiOutput("dateChoice"),
                           
                           hr(),
                           
                           # add species choice
                           selectInput("species", "Choose species:", 
                                       choices = species,
                                       selected = "right", multiple = T),
                           
                           hr(),
                           
                           # add platform choice
                           selectInput("platform", "Choose platform(s):", multiple = T,
                                       choices = c("Slocum Glider" = "slocum",
                                                   "Wave Glider" = "wave",
                                                   "Plane" = "plane",
                                                   "Vessel" = "vessel",
                                                   "Buoy" = "buoy",
                                                   "Opportunistic" = "opportunistic"), 
                                       selected = c('slocum', 
                                                    'wave', 
                                                    'plane',
                                                    'vessel',
                                                    'buoy', 
                                                    'opportunistic')),
                           
                           hr(),
                           
                           # unlock preliminary data
                           tagAppendAttributes(
                               passwordInput("password", 'Show unverified data:', value = "",
                                         placeholder = 'Enter password'),
                               `data-proxy-click` = "go"
                           ),
                           helpText('To request the password please send a brief description 
                                    of your affiliation and intentions to hansen.johnson@dal.ca'),

                           hr(),
                           
                           # add button to update date
                           actionButton("go", "Go!",
                                        style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
                           
                           # add button to re-center
                           actionButton("zoom", "Center map")
                  ),
                  
                  # layers tab ----------------------------------------------------------
                  
                  # Customize plotting
                  tabPanel(title = 'Layers',
                           
                           #color by
                           selectInput("colorby", "Color by:", choices =
                                         c('Detection Score' = 'score',
                                           'Year' = 'year',
                                           'Day of year' = 'yday',
                                           'Platform' = 'platform',
                                           'Platform name' = 'name',
                                           'Number' = 'number',
                                           'Species' = 'species',
                                           'Latitude' = 'lat',
                                           'Longitude' = 'lon',
                                           'Deployment' = 'id'), selected = 'score'),
                           
                           # color palette
                           selectInput("pal", "Choose color palette:",
                                       c("Temperature" = 2,
                                         "Viridis" = 8,
                                         "Gebco" = 6,
                                         "Heat colors" = 1,
                                         "Jet" = 7,
                                         "Salinity" = 3,
                                         "Density" = 4,
                                         "Chlorophyll" = 5), selected = 8),
                           
                           hr(),
                           
                           h5(strong('Choose layer(s):')),
                           
                           # Survey layers
                           helpText(tags$em('Survey Layers')),
                           
                           checkboxInput("tracks", label = 'Tracks', value = T),
                           
                           checkboxInput("possible", label = 'Possible detections/sightings', value = T),
                           
                           checkboxInput("detected", 
                                         label = 'Definite detections/sightings', value = T),
                           
                           checkboxInput("sono", label = 'Sonobuoys', value = F),
                           
                           checkboxInput("latest", label = 'Latest robot positions', value = T),
                           
                           # Map layers
                           helpText(tags$em('Map Layers')),
                           
                           checkboxInput("mpa", 
                                         label = 'Protected areas', value = T),
                           
                           checkboxInput("tss", 
                                         label = 'Shipping lanes', value = T),
                           
                           checkboxInput("legend", label = 'Legends', value = T),
                           
                           # 2018 protections
                           helpText(tags$em('2018 Protections')),
                           
                           checkboxInput("tc_lanes", 
                                         label = 'Dynamic Shipping lanes', value = F),
                           
                           tags$div(
                             `style` = "padding-left: 20px",
                             HTML(paste(tags$em("Status: "), tags$span(style="color:red", "ACTIVE"), sep = ""))
                           ),
                           
                           checkboxInput("tc_zone", 
                                         label = 'Reduced Speed Zone', value = F),
                           
                           checkboxInput("static_zone", 
                                         label = 'Static fishery closure', value = F),
                           
                           tags$a(href="https://www.canada.ca/en/fisheries-oceans/news/2018/03/government-of-canada-unveils-its-plan-for-protecting-north-atlantic-right-whales-in-20180.html", "Click here for details")
                           
                  ),
                  
                  # draw tab ----------------------------------------------------------
                  
                  # Coordinate editor
                  tabPanel(title = 'Draw', 
                           
                           # help text
                           helpText('Drop new points with ',icon("map-marker", lib = 'glyphicon'), 
                                    '. Edit points with ', icon("edit", lib = 'glyphicon'),
                                    ' or via the table below. Remove one or all points with', 
                                    icon("trash", lib = 'glyphicon'), '. Distances are along-path [km]'),
                           
                           # coordinate table
                           strong('Coordinate list'),
                           rHandsontableOutput("hot", height = 250),
                           helpText('Hint: switch tabs to add points more quickly'),
                           
                           # calculate distance
                           checkboxInput("dist", label = 'Calculate distance?', value = T),
                           
                           # round coordinates
                           strong('Round coordinates'),
                           helpText('Choose number of decimal places'),
                           numericInput('dig', label = NULL, value = 1,
                                        min = 0, max = 6, step=1, width = 50),
                           actionButton('round', 'Round'),
                           
                           # connect points
                           radioButtons('shp', label = 'Connection between points', 
                                        choices = c('None', 'Line', 'Polygon'), 
                                        selected = 'None', inline = F),
                           strong('Save coordinates'), br(),
                           
                           # download
                           downloadButton("downloadData", "Save")
                  )    
           )
           
           # box(title = 'Share', width = NULL,
           #   
           #   # bookmarking
           #   bookmarkButton(),
           #   
           #   helpText('Use the above button to bookmark the app in its current state 
           #                          so you can easily share it with others')
           #   
           # )
    ),
    
    # main display --------------------------------------------------------------------
    column(width = 9,
           
           # Map
           box(width = NULL, solidHeader = T,collapsible = T, 
               status = 'primary', title = 'Map', 
               
               leafletOutput("map", height = 550)
               
           ),
           
           # Plot
           box(width = NULL, solidHeader = T,collapsible = T, 
               status = 'primary', title = 'Plot', 
               
               plotlyOutput("graph"),
               
               # plot inBounds switch
               checkboxInput("plotInBounds", 
                             label = 'Only plot data within map bounds?', value = T)
               
           ),
           
           # Currently viewing
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Currently viewing:', 
               status = 'primary',
               
               htmlOutput("summary")
           )
    )
  )
)


# construct ui ----------------------------------------------------------

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)