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
           box(width = NULL, status = "warning", collapsible = T,
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
           box(width = NULL, status = "warning", collapsible = T,
               
               # add platform choice
               selectInput("platform", "Choose platform(s):", 
                           c("Slocum Glider" = "slocum",
                             "Wave Glider" = "wave",
                             "Buoy" = "buoy",
                             "Plane" = "plane",
                             "Vessel" = "vessel"),
                           selected = 'slocum', multiple = T),
               
               # add species choice
               selectInput("species", "Choose species:", choices = species, 
                           selected = "right", multiple = F),
               
               # add button to zoom
               actionButton("zoom", "Zoom to selection"),
               
               # checkboxes
               h5(strong('Choose layer(s):')),
               checkboxInput("tracks", label = 'Show tracks?', value = T),
               checkboxInput("detected", label = 'Show definite detections?', value = T),
               checkboxInput("possible", label = 'Show possible detections?', value = F)
           ),
           
           box(width = NULL, status = "warning",collapsible = T,
               
               #color by
               selectInput("colorby", "Color by:", choices =
                             c('Detection Score' = 'score',
                               'Year' = 'year',
                               'Day of year' = 'yday',
                               'Platform' = 'platform',
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
           box(width = NULL, solidHeader = TRUE,collapsible = T,
               leafletOutput("map", height = 500)
           ),
           
           # stats
           box(width = NULL,collapsible = T,
               h5(strong('You are currently viewing:')),
               htmlOutput("summary")
           ),
           
           # details
           box(width = NULL,title = 'About',collapsible = T,
               p('These data were collected by various autonomous platforms equipped with the Low Frequency Detection and Classification System (LFDCS) developed by Dr. Mark Baumgartner at the Woods Hole Oceanographic Institution. For more details on the system, platforms, deployments, or research please visit the Robots4Whales site at: ', tags$a(href="dcs.whoi.edu", "dcs.whoi.edu")),
               p('Please note that while Slocum gliders and moored buoys are considered reliable and operational platforms, the wave glider is still experimental. It likely has a lower probability of detection than the other platforms, so absent detections should be treated with even more caution.'),
               p('Source code for this application is available ', tags$a(href="https://github.com/hansenjohnson/dcs_map", "here."), 'For more details, comments or suggestions, please contact Hansen Johnson at hansen(dot)johnson(at)dal.ca')
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