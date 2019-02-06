# ui.R
# WhaleMap - a Shiny app for visualizing whale survey data

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(leaflet))
suppressPackageStartupMessages(library(htmltools))
suppressPackageStartupMessages(library(htmlwidgets))
suppressPackageStartupMessages(library(maptools))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(oce))
suppressPackageStartupMessages(library(plotly))
suppressPackageStartupMessages(library(shinydashboard))

# user input --------------------------------------------------------------

years = c('2014', '2015', '2016', '2017', '2018', '2019')

# header ----------------------------------------------------------------------

header <-  dashboardHeader(title = 'WhaleMap',
                           
                           # data
                           dropdownMenu(
                             type = "notifications",
                             icon = 'More Information',
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
                                              href = "https://github.com/hansenjohnson/WhaleMap/issues"),
                             notificationItem("Home",
                                              icon = icon("home"),
                                              href = "/"),
                             notificationItem(Sys.getenv("R_SHNYSRVINST"),
                                              icon = icon("tag"),
                                              href = "#")
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
    
    # editor tab ----------------------------------------------------------
    
    # notice
    column(width = 12,
           box(width = NULL, solidHeader = T, collapsible = F, 
               status = 'danger', 
               
               p("WhaleMap currently focuses on Canadian waters. For a comprehensive overview of the latest observations in the US go to:", 
                 a(href="https://www.nefsc.noaa.gov/psb/surveys/", "https://www.nefsc.noaa.gov/psb/surveys/"), align = "center")
           )),
    
    # left column
    column(width = 3,
           
           # translator
           box(width = NULL, solidHeader = F, collapsible = T, title = 'Translate / Traduire', status = 'primary',
               HTML('
                  <div id="google_translate_element"></div>
                  
                  <script type="text/javascript">
                  function googleTranslateElementInit() {
                  new google.translate.TranslateElement({pageLanguage: \'en\', layout: google.translate.TranslateElement.InlineLayout.SIMPLE},   \'google_translate_element\');
                  }
                  </script>
                  
                  <script type="text/javascript" src="//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"></script>
                  ')
           ),
           
           # map editor
           tabBox(title = 'Editor', width = NULL,
                  
                  # Select Data    
                  tabPanel(title = 'Data',
                           
                           # choose year
                           selectInput("year", label = 'Choose year(s):',
                                       choices = years,
                                       selected = '2019', multiple = TRUE),
                           
                           hr(),
                           
                           # choose date input
                           radioButtons("dateType", label = 'Choose dates(s):', 
                                        choiceNames = c('Specific date:','Range of dates:'),
                                        choiceValues = c('select', 'range'), selected = 'range'),
                           
                           uiOutput("dateChoice"),
                           
                           hr(),
                           
                           # add species choice
                           selectInput("species", "Choose species:", 
                                       choices = c("Right whale" = "right",
                                                   "Fin whale" = "fin",
                                                   "Blue whale" = "blue",
                                                   "Sei whale" = "sei",
                                                   "Humpback whale" = "humpback"), 
                                       selected = "right", 
                                       multiple = T),
                           
                           hr(),
                           
                           # add platform choice
                           selectInput("platform", "Choose platform(s):", multiple = T,
                                       choices = c("Slocum Glider" = "slocum",
                                                   "Plane" = "plane",
                                                   "Vessel" = "vessel",
                                                   "Buoy" = "buoy",
                                                   "Opportunistic" = "opportunistic"), 
                                       selected = c('slocum', 
                                                    'plane',
                                                    'vessel',
                                                    'buoy', 
                                                    'opportunistic')),
                           
                           hr(),
                           
                           #color by
                           selectInput("colorby", "Color observations by:", choices =
                                         c('Score' = 'score',
                                           'Species' = 'species',
                                           'Day of year' = 'yday',
                                           'Year' = 'year',
                                           'Platform' = 'platform',
                                           'Platform name' = 'name',
                                           'Number' = 'number',
                                           'Latitude' = 'lat',
                                           'Longitude' = 'lon',
                                           'Deployment' = 'id'), selected = 'score'),
                           
                           hr(),
                           
                           # unlock preliminary data
                           tagAppendAttributes(
                             passwordInput("password", 'Show unverified data:', value = "",
                                           placeholder = 'Enter password'),
                             `data-proxy-click` = "go"
                           ),
                           
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
                           helpText(tags$em('2019 Protections')),
                           
                           checkboxInput("tc_lanes", 
                                         label = 'Dynamic Shipping lanes', value = F),
                           
                           checkboxInput("tc_zone", 
                                         label = 'Reduced Speed Zone', value = F),
                           
                           checkboxInput("static_zone", 
                                         label = 'Static fishery closure', value = F),
                           
                           checkboxInput("forage_areas", 
                                         label = 'Area subject to temporary fishery closure protocol', value = F),
                           
                           tags$a(href="https://www.canada.ca/en/fisheries-oceans/news/2018/03/government-of-canada-unveils-its-plan-for-protecting-north-atlantic-right-whales-in-20180.html", "Click here for details")
                           
                  )
           )
    ),
    
    # main display --------------------------------------------------------------------
    column(width = 9,
           
           # Map
           box(width = NULL, solidHeader = T,collapsible = T, 
               status = 'primary', title = 'Map', 
               
               leafletOutput("map", height = 550),
               
               helpText("Please note that much of these data are preliminary and subject to change, and
                        that few or no observations may reflect a lack of effort rather than a lack of whales")
           ),
           
           # Plot
           box(width = NULL, solidHeader = T,collapsible = T, 
               status = 'primary', title = 'Plot', 
               
               plotlyOutput("graph"),
               
               # define blue effort line
               helpText('The blue dashed line indicates days with survey effort'),
               
               # plot inBounds switch
               checkboxInput("plotInBounds", 
                             label = 'Only plot data within map bounds?', value = T)
               
           ),
           
           # Currently viewing
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Currently viewing:', 
               status = 'primary',
               
               htmlOutput("summary")
           ),
           
           # Status table
           box(width = NULL, solidHeader = T,collapsible = T, title = 'Status:', 
               status = 'primary',
               
               tableOutput("status"),
               helpText('This shows when data from a particular platform were last processed by the WhaleMap
                        system. Errors in processing are indicated by an error message in place of a timestamp.')
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