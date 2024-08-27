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
                             notificationItem("User Guide",
                                              icon = icon('info-sign', lib = 'glyphicon'),
                                              href = "https://whalemap.org/guide.html"),
                             notificationItem("Cite",
                                              icon = icon('education', lib = 'glyphicon'),
                                              href = "https://whalemap.org/#cite"),
                             notificationItem("Contact",
                                              icon = icon('envelope', lib = 'glyphicon'),
                                              href = "https://whalemap.org/#contact"),
                             notificationItem("Code",
                                              icon = icon('console', lib = 'glyphicon'),
                                              href = "https://github.com/hansenjohnson/WhaleMap"),
                             notificationItem("View/Report Issues",
                                              icon = icon('exclamation-sign', lib = 'glyphicon'),
                                              href = "https://github.com/hansenjohnson/WhaleMap/issues"),
                             notificationItem("Home",
                                              icon = icon("home"),
                                              href = "https://whalemap.org/"),
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
    
    # sidebar ----------------------------------------------------------
    
    column(width = 3,
           
           # map editor
           tabBox(title = NULL, width = NULL,
                  
                  # data tab ----------------------------------------------------------
                  
                  # Select Data    
                  tabPanel(title = 'Data',
                           
                           # choose date input
                           radioButtons("dateType", label = 'Choose date(s):', 
                                        choiceNames = c('Specific date','Date range','Range among years'),
                                        choiceValues = c('select', 'range', 'multiyear'), selected = 'range'),
                           
                           uiOutput("dateChoice"),
                           
                           hr(),
                           
                           # add platform choice
                           selectInput("platform", "Choose platform(s):", multiple = T,
                                       choices = c("Slocum Glider" = "slocum",
                                                   "Plane" = "plane",
                                                   "Vessel" = "vessel",
                                                   'RPAS' = 'rpas',
                                                   "Buoy" = "buoy",
                                                   "Opportunistic" = "opportunistic"), 
                                       selected = c('slocum', 
                                                    'plane',
                                                    'vessel',
                                                    'rpas',
                                                    'buoy', 
                                                    'opportunistic')),
                           
                           hr(),

                           # add platform name choice
                           selectInput("name", "Choose platform name(s):", 
                                       multiple = T,
                                       choices = c('All', name_choices),
                                       selected = 'All', selectize = TRUE),
                           
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
                           
                           # add data source choice
                           selectInput("dsource", "Choose data source(s):", 
                                       choices = c("NARWC",
                                                   "WhaleMap",
                                                   "WhaleInsight",
                                                   "RWSAS"), 
                                       selected = c("NARWC",
                                                    "WhaleMap",
                                                    "WhaleInsight",
                                                    "RWSAS"),
                                       multiple = T),
                           
                           hr(),
                           
                           # checkbox data layers
                           
                           h5(strong('Choose data layer(s):')),
                           
                           checkboxInput("tracks", label = 'Effort', value = T),
                           
                           checkboxInput("possible", 
                                         label = 'Possible observations', value = T),
                           
                           checkboxInput("detected", 
                                         label = 'Definite observations', value = T),
                           
                           hr(),
                           
                           # unlock preliminary data
                           tagAppendAttributes(
                             passwordInput("password", 'Show unverified data:', value = "",
                                           placeholder = 'Enter password'),
                             `data-proxy-click` = "go"
                           )
                           
                  ),
                  
                  # colors tab ----------------------------------------------------------
                  
                  # Customize plotting
                  tabPanel(title = 'Colors',
                           
                           # Observations color variable
                           selectInput("colorby_obs", "Color observations by:", 
                                       choices = colorby_obs_choices, 
                                       selected = colorby_obs_choices[1]),
                           
                           # Observations color palette
                           selectInput("pal_obs", "Choose color palette:", 
                                       choices = palette_list, selected = NULL),
                           
                           hr(),
                           
                           # Tracks color variable
                           selectInput("colorby_trk", "Color effort by:", 
                                       choices = colorby_trk_choices, 
                                       selected = colorby_trk_choices[1]),
                           
                           # Tracks color palette
                           selectInput("pal_trk", "Choose color palette:", 
                                       choices =  palette_list, selected = NULL)
                           
                  ),
                  # layers tab ----------------------------------------------------------
                  
                  # Customize plotting
                  tabPanel(title = 'Layers',
                           
                           # Basemap
                           selectInput("basemap", label = "Choose basemap:",
                                       choices =  basemap_choices, 
                                       selected = basemap_choices[1]),
                           
                           hr(),
                           
                           helpText(tags$em('Map layers')),
                           
                           checkboxInput("graticules", label = 'Graticules', value = F),
                           
                           # checkboxInput("noaa", label = 'NOAA charts', value = F),
                           
                           checkboxInput("latest", label = 'Latest robot positions', value = T),
                           
                           checkboxInput("tss", label = 'Shipping lanes', value = T),
                           
                           checkboxInput("legend", label = 'Legends', value = T),
                           
                           # Canadian management layers
                           helpText(tags$em('Canadian management areas')),
                           
                           checkboxInput("critical_habitat_zone", 
                                         label = 'Critical habitat areas', value = T),
                           
                           checkboxInput("dfo_zone", value = F,
                                         label = span("Areas subject to dynamic closure protocol for fisheries", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "http://www.dfo-mpo.gc.ca/fisheries-peches/commercial-commerciale/atl-arc/narw-bnan/management-gestion-eng.html"))),
                           
                           checkboxInput("dfo_lines", value = F,
                                         label = span("Shallow water protocol lines (10 and 20 fathoms)", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "http://www.dfo-mpo.gc.ca/fisheries-peches/commercial-commerciale/atl-arc/narw-bnan/management-gestion-eng.html"))),
                           
                           checkboxInput("tc_zone", value = F,
                                         label = span("Vessel traffic management areas", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.tc.gc.ca/en/services/marine/navigation-marine-conditions/protecting-north-atlantic-right-whales-collisions-ships-gulf-st-lawrence.html"))),
                           
                           checkboxInput("tc_ra", value = F,
                                         label = span("Transport Canada restricted area",
                                                      tags$a(icon("info-sign", lib = "glyphicon"),
                                                             target="_blank",
                                                             href = "https://tc.canada.ca/en/ministerial-orders-interim-orders-directives-directions-response-letters/interim-order-protection-north-atlantic-right-whales-eubalaena-glacialis-near-shediac-valley"))),
                           
                           # USA management layers
                           helpText(tags$em('US management areas')),
                           
                           checkboxInput("us_lobster", value = F,
                                         label = span("Lobster management areas", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.fisheries.noaa.gov/resource/map/lobster-management-areas"))),
                           
                           checkboxInput("alwtrp", value = F,
                                         label = span("US fishery seasonal restricted areas", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.fisheries.noaa.gov/resource/map/new-and-existing-restricted-areas-2021-atlantic-large-whale-take-reduction-plan"))),
                           
                           checkboxInput("sma", value = T,
                                         label = span("Seasonal management areas", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.fisheries.noaa.gov/national/endangered-species-conservation/reducing-vessel-strikes-north-atlantic-right-whales#seasonal-management-areas---northeast"))),
                           checkboxInput("dma", value = T,
                                         label = span("Slow Zones", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.fisheries.noaa.gov/national/endangered-species-conservation/reducing-vessel-strikes-north-atlantic-right-whales#dynamic-management-areas"))),
                           checkboxInput("spd", value = F,
                                         label = span("Proposed right whale seasonal speed zones", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.fisheries.noaa.gov/resource/data/proposed-right-whale-seasonal-speed-zones"))),
                           checkboxInput("wind_planning", value = F,
                                         label = span("Wind planning areas", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data"))),
                           checkboxInput("wind_lease", value = F,
                                         label = span("Wind lease areas", 
                                                      tags$a(icon("info-sign", lib = "glyphicon"), 
                                                             target="_blank",
                                                             href = "https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data")))
                  )
           )
    ),
    
    # main display --------------------------------------------------------------------
    column(width = 9,
           
           # Map
           box(width = NULL, solidHeader = T,collapsible = T, 
               status = 'primary', title = 'Map', 
               
               leafletOutput("map", height = 550),
               
               helpText("These data are preliminary data, subject to change, and not to be used without permission from the contributor(s)")
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
    add_busy_spinner(
      color = "#FF0000",
      timeout = 300,
      spin = 'rotating-plane',
      height = '25px',
      width = '30px',
      position = 'bottom-left',
      margins = c(10, 45)
    ),
    actionButton(
      "go",
      "Go!",
      width = '200%',
      class = "btn-primary btn-lg",
      style = "color: #fff; background-color: #337ab7; border-color: #2e6da4"
    ),
    left = 20,
    bottom = 10,
    style = "z-index:1000;"
  )
)

# construct ui ----------------------------------------------------------

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)