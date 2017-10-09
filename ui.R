# ui.R

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
# library(shinyjqui)
#library(shinycssloaders)

# user input --------------------------------------------------------------

begin_date = as.Date('2017-01-01')
end_date = as.Date('2017-12-30')

years = c('2014', '2015', '2016', '2017')
species = c('right', 'sei', 'fin', 'humpback')

# ui ----------------------------------------------------------------------

# header <-  dashboardHeader(title = list(tags$a(href='https://leviathan.ocean.dal.ca',
#                                  icon("home")), 'Whale Surveys'))

header <-  dashboardHeader(title = 'Whale Surveys',
                            
                           # data
                           dropdownMenu(
                              type = "notifications",
                              icon = icon('info-sign', lib = 'glyphicon'),
                              badgeStatus = NULL,
                              headerText = "",
                              notificationItem("User manual / help",
                                               icon = icon('question-sign', lib = 'glyphicon'),
                                               href = "http://leviathan.ocean.dal.ca/WhaleMap/help.html"),
                              notificationItem("Data details",
                                               icon = icon('signal', lib = 'glyphicon'),
                                               href = "http://leviathan.ocean.dal.ca/WhaleMap/data_details.html")
                              ),
                           
                           # leviathan
                              dropdownMenu(
                                type = "notifications",
                                icon = 'leviathan.ocean.dal.ca',
                                badgeStatus = NULL,
                                headerText = "",
                                notificationItem("Home",
                                                 icon = icon("home"),
                                                 href = "http://leviathan.ocean.dal.ca"),
                                notificationItem("2017 right whale map",
                                                 icon = icon("map"),
                                                 href = "http://leviathan.ocean.dal.ca/right_whale_map/"),
                                notificationItem("Live Glider",
                                                 icon = icon("plane", lib = 'glyphicon'),
                                                 href = "http://leviathan.ocean.dal.ca/live_glider/")
                              
                            )
)
  
# body --------------------------------------------------------------------

body <- dashboardBody(
  fluidRow(
    
    # sidebar --------------------------------------------------------------------
    column(width = 3,
           
           # Select Data
           box(width = NULL, solidHeader = F, status = "warning", 
               collapsible = T, title = 'Select Data',
               
               # choose year input
               radioButtons("yearType", label = 'Choose year(s):', 
                            choiceNames = c('Specific year(s):','Range of years:'),
                            choiceValues = c('select', 'range')),
               
               uiOutput("yearChoice"),
               
               hr(),
               
               # add date range choice
               sliderInput("range", "Choose date range:", begin_date, end_date,
                           value = c(Sys.Date()-30, Sys.Date()), timeFormat = '%b-%d',
                           animate = F),
               
               hr(),
               
               # add species choice
               selectInput("species", "Choose species:", choices = species, 
                           selected = "right", multiple = F),
               
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
               
               # add button to update date
               actionButton("go", "Go!",
                            style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
               
               # add button to re-center
               actionButton("zoom", "Center map"),
               
               helpText('Please be patient if viewing data from many years. 
                                       Consider turning tracks \'off\' below to speed up plotting.'),

               # update live glider
               actionButton("update", label = 'Update glider data')
               
           ),
           
           # Customize plotting
           box(width = NULL, solidHeader = F, status = "warning", 
               collapsible = T, title = 'Customize plots',
               
               #color by
               selectInput("colorby", "Color by:", choices =
                             c('Detection Score' = 'score',
                               'Year' = 'year',
                               'Day of year' = 'yday',
                               'Platform' = 'platform',
                               'Platform name' = 'name',
                               'Number' = 'number',
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
               checkboxInput("tracks", label = 'Tracks', value = T),
               
               checkboxInput("possible", label = 'Possible detections', value = T),
               
               checkboxInput("detected", 
                             label = 'Definite detections/sightings', value = T),
               
               checkboxInput("poly", 
                             label = 'Regions', value = T),
               
               # legend switch
               checkboxInput("legend", label = 'Legends', value = T)
               
           )
    ),
    
    # main display --------------------------------------------------------------------
    column(width = 9,
           
           # Map
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Map', 
               status = 'primary',
               
               leafletOutput("map", height = 550)
               
           ),
           
           # Plot
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Plot', 
               status = 'primary', collapsed = F,
               
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