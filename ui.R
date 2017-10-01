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
library(shinyjqui)

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
    jqui_sortabled(column(width = 3,
           
           # Choose year and date range
           box(width = NULL, solidHeader = F, status = "warning", collapsible = T, title = 'Time Input',
               # add year choice
               selectInput("year", "Choose year(s):", 
                           choices = c('2014',
                                       '2015',
                                       '2016',
                                       '2017'), 
                           selected = '2017', multiple = T),
               
               # add date range choice
               sliderInput("range", "Choose date range:", begin_date, end_date,
                           value = c(begin_date, end_date), timeFormat = '%b-%d',
                           animate = TRUE),
               # animate = animationOptions(interval = 1))
               
               # add button to zoom
               actionButton("advance", "Advance 7 days"),
               
               helpText('Hint: drag sliders to the left and click \'Advance 7 days\' to see detections evolve over time')
           ),
           
           # Choose species and platform
           box(width = NULL, solidHeader = F, status = "warning", collapsible = T, title = 'Survey Input',
               
               # add platform choice
               selectInput("platform", "Choose platform(s):", 
                           c("Slocum Glider" = "slocum",
                             "Wave Glider" = "wave",
                             "Plane" = "plane",
                             "Vessel" = "vessel",
                             "Buoy" = "buoy",
                             "Opportunistic" = "opportunistic"),
                           selected = 'slocum', multiple = T),
               
               # add species choice
               selectInput("species", "Choose species:", choices = species, 
                           selected = "right", multiple = F),
               
               # add button to zoom
               actionButton("zoom", "Zoom to selection"),
               
               # checkboxes
               h5(strong('Choose layer(s):')),
               checkboxInput("tracks", label = 'Show tracks?', value = T),
               checkboxInput("detected", label = 'Show definite detections/sightings?', value = T),
               checkboxInput("possible", label = 'Show possible detections?', value = F)
           ),
           
           box(width = NULL, solidHeader = F, status = "warning", collapsible = T, title = 'Plot Input',
               
               #color by
               selectInput("colorby", "Color by:", choices =
                             c('Detection Score' = 'score',
                               'Year' = 'year',
                               'Day of year' = 'yday',
                               'Platform' = 'platform',
                               'Platform name' = 'name',
                               'Number' = 'number',
                               'Deployment' = 'id'), selected = 'score'),
               
               # color palette
               selectInput("pal", "Color palette:",
                           c("Temperature" = 2,
                             "Viridis" = 8,
                             "Gebco" = 6,
                             "Heat colors" = 1,
                             "Jet" = 7,
                             "Salinity" = 3,
                             "Density" = 4,
                             "Chlorophyll" = 5), selected = 2),
               
               checkboxInput("legend", label = 'Show legend?', value = T)
           )
    )),
    
    # main display --------------------------------------------------------------------
    jqui_sortabled(column(width = 9,
           
           # map
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Map', status = 'primary',
               leafletOutput("map", height = 500)
           ),
           
           # stats
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Currently viewing:', status = 'primary',
               htmlOutput("summary")
           ),
           
           # graph
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Graph', status = 'primary',
               plotlyOutput("graph")
           ),
               
           # details
           box(width = NULL, solidHeader = T,collapsible = T, title = 'About', status = 'primary',
               p('More details coming soon...'),
               p('Please contact Hansen Johnson at hansen.johnson(AT)dal.ca for any questions, comments, suggestions, etc')
           )
    )
  ))
)

# construct ui ----------------------------------------------------------

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)