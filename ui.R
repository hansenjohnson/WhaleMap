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

header <- dashboardHeader(
  title = "Whale Surveys"
)

# body --------------------------------------------------------------------

body <- dashboardBody(
  fluidRow(
    
    # sidebar --------------------------------------------------------------------
    column(width = 3,
           
           # Time Input
           box(width = NULL, solidHeader = F, status = "warning", 
               collapsible = T, title = 'Time Input',
               
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
               
               # add button to update date
               actionButton("go", "Go!",
                            style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
               
               # add button to re-center
               actionButton("zoom", "Center map"),
               
               helpText('Please be patient if viewing data from many years. 
                                       Consider turning tracks \'off\' below to speed up plotting.')
               
           ),
           
           # Survey Input
           box(width = NULL, solidHeader = F, status = "warning", 
               collapsible = T, title = 'Survey Input',
               
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
               
               # add species choice
               selectInput("species", "Choose species:", choices = species, 
                           selected = "right", multiple = F),
               
               hr(),
               
               # checkboxes
               h5(strong('Choose layer(s):')),
               checkboxInput("tracks", label = 'Show tracks?', value = T),
               
               checkboxInput("possible", label = 'Show possible detections?', value = T),
               
               checkboxInput("detected", 
                             label = 'Show definite detections/sightings?', value = T),
               
               checkboxInput("poly", 
                             label = 'Show regions?', value = T)
               
           ),
           
           box(width = NULL, solidHeader = F, status = "warning", 
               collapsible = T, title = 'Plot Input',
               
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
               
               # legend switch
               checkboxInput("legend", label = 'Show legend?', value = T),
               
               # plot inBounds switch
               checkboxInput("plotInBounds", 
                             label = 'Plot only data within map bounds?', value = T),
               
               # color palette
               selectInput("pal", "Choose color palette:",
                           c("Temperature" = 2,
                             "Viridis" = 8,
                             "Gebco" = 6,
                             "Heat colors" = 1,
                             "Jet" = 7,
                             "Salinity" = 3,
                             "Density" = 4,
                             "Chlorophyll" = 5), selected = 8)
           )
    ),
    
    # main display --------------------------------------------------------------------
    column(width = 9,
           
           # Map
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Map', 
               status = 'primary',
               
               leafletOutput("map", height = 600)
               
           ),
           
           # Plot
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Plot', 
               status = 'primary', collapsed = T,
               
               plotlyOutput("graph")
               
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