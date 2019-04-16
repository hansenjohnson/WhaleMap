# ui.R
# WhaleMap - a Shiny app for visualizing whale survey data

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
                           )
                           
                           # hr(),
                           # 
                           # # add button to update date
                           # actionButton("go", "Go!",
                           #              style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
                           # 
                           # # add button to re-center
                           # actionButton("zoom", "Center map")
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
                           
                           checkboxInput("tss", 
                                         label = 'Shipping lanes', value = T),
                           
                           checkboxInput("legend", label = 'Legends', value = T),
                           
                           # Management layers
                           helpText(tags$em('Canadian management')),
                           
                           checkboxInput("critical_habitat_zone", 
                                         label = 'Critical habitat areas', value = T),
                           
                           checkboxInput("static_fishing_zone", value = F,
                                         label = span("Static fishery closure", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"),
                                                             target="_blank",
                                                             href = "http://www.dfo-mpo.gc.ca/species-especes/mammals-mammiferes/narightwhale-baleinenoirean/fm-gp/index-eng.html"))),
                           
                           checkboxInput("dynamic_fishing_zone", value = F,
                                         label = span("Dynamic fishing zone", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "http://www.dfo-mpo.gc.ca/species-especes/mammals-mammiferes/narightwhale-baleinenoirean/fm-gp/index-eng.html"))),
                           
                           checkboxInput("dynamic_fishing_grid", value = F,
                                         label = span("Dynamic fishing grid", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"),
                                                             target="_blank",
                                                             href = "http://www.dfo-mpo.gc.ca/species-especes/mammals-mammiferes/narightwhale-baleinenoirean/fm-gp/index-eng.html"))),
                           
                           checkboxInput("dynamic_fishing_10_fathom_contour", value = F,
                                         label = span("Dynamic fishing: 10-fathom contour", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"),
                                                             target="_blank",
                                                             href = "http://www.dfo-mpo.gc.ca/species-especes/mammals-mammiferes/narightwhale-baleinenoirean/fm-gp/index-eng.html"))),
                           
                           checkboxInput("dynamic_fishing_20_fathom_contour", value = F,
                                         label = span("Dynamic fishing: 20-fathom contour", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "http://www.dfo-mpo.gc.ca/species-especes/mammals-mammiferes/narightwhale-baleinenoirean/fm-gp/index-eng.html"))),
                           
                           checkboxInput("static_shipping_zone", value = F,
                                         label = span("Static shipping zone", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "http://www.tc.gc.ca/en/services/marine/navigation-marine-conditions/protecting-north-atlantic-right-whales-collisions-ships-gulf-st-lawrence.html#toc_2"))),
                                         
                           checkboxInput("dynamic_shipping_zone", value = F,
                                         label = span("Dynamic vessel slow zone", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "http://www.tc.gc.ca/en/services/marine/navigation-marine-conditions/protecting-north-atlantic-right-whales-collisions-ships-gulf-st-lawrence.html#toc_3")))
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
  ),
  
  # floating go button
  fixedPanel(
    actionButton("go", "Go!",
                 style="color: #fff; background-color: #337ab7; border-color: #2e6da4"),
    left = 10,
    bottom = 10,
    style="z-index:1000;"
  )
)

# construct ui ----------------------------------------------------------

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)