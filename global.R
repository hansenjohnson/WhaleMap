# global.R
# WhaleMap - a Shiny app for visualizing whale survey data


# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(leaflet))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(htmltools))
suppressPackageStartupMessages(library(htmlwidgets))
suppressPackageStartupMessages(library(maptools))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(oce))
suppressPackageStartupMessages(library(shinydashboard))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(plotly))
suppressPackageStartupMessages(library(leaflet.extras))
suppressPackageStartupMessages(library(shinybusy))
source('R/functions.R')

# definitions -------------------------------------------------------------

# basemap choices
basemap_choices = c("ESRI Ocean" = "Esri.OceanBasemap",
                    "OpenStreetMap" = "OpenStreetMap.Mapnik",
                    "Black and white" = "Stamen.TonerBackground",
                    "ESRI Imagery" = "Esri.WorldImagery",
                    "Grey" = "Esri.WorldGrayCanvas",
                    "Blank - light" = "CartoDB.PositronNoLabels",
                    "Blank - dark" = "CartoDB.DarkMatterNoLabels")

# define color palette list to choose from
palette_list = c("Default", "Viridis", "Heat", "Jet", "Spectral", "Greys", 
                 "RedBlue", "RedYellowBlue", "Dark", "Paired", "Accent", 
                 "Set1", "Set2")

# define score colors
score_cols = c('definite acoustic' = 'red', 
               'possible acoustic' = 'yellow', 
               'definite visual' = 'darkslategray',
               'possible visual' = 'gray')

platform_cols = c(
  'plane' = '#8B6914',
  'vessel' = 'black',
  'slocum' = 'blue',
  'rpas' = 'purple'
)

# observation colorby choices
colorby_obs_choices = 
  c('Score' = 'score',
  'Species' = 'species',
  'Calves' = 'calves',
  'Day of year' = 'yday',
  'Year' = 'year',
  'Platform' = 'platform',
  'Platform name' = 'name',
  'Number' = 'number',
  'Latitude' = 'lat',
  'Longitude' = 'lon',
  'Deployment' = 'id')

# track colorby choices
colorby_trk_choices = 
  c('Platform' = 'platform',
    'Year' = 'year',
    'Platform name' = 'name',
    'Deployment' = 'id')

# define visual and acoustic platforms
visual_platforms = c('plane', 'vessel', 'rpas')
acoustic_platforms = c('slocum', 'buoy', 'wave')

# define track point plotting threshold
npts = 250000

# define time lag for startup plotting
tlag = 14 # days

# make dcs icons
dcsIcons = iconList(
  slocum = makeIcon("icons/slocum.png", iconWidth = 38, iconHeight = 38),
  wave = makeIcon("icons/wave.png", iconWidth = 35, iconHeight = 30),
  buoy = makeIcon("icons/buoy.png", iconWidth = 44, iconHeight = 34, iconAnchorX = 22, iconAnchorY = 28)
)

# make sono icon
sonoIcon = makeIcon("icons/sono.png", iconWidth = 10, iconHeight = 45)

# status file
status_file = 'data/processed/status.txt'
index_file = 'status_index.csv'

# graticule intervals
graticule_ints = list(
  data.frame('start' = 0, 'end' = 2, 'interval' = 60),
  data.frame('start' = 3, 'end' = 3, 'interval' = 20),
  data.frame('start' = 4, 'end' = 4, 'interval' = 10),
  data.frame('start' = 5, 'end' = 5, 'interval' = 5),
  data.frame('start' = 6, 'end' = 6, 'interval' = 2),
  data.frame('start' = 7, 'end' = 7, 'interval' = 1),
  data.frame('start' = 8, 'end' = 8, 'interval' = 0.5),
  data.frame('start' = 9, 'end' = 9, 'interval' = 0.25),
  data.frame('start' = 10, 'end' = 15, 'interval' = 0.1)
)

# hidden platforms
hidden_platforms = c('cp_king_air', 'jasco_test')

# load data ---------------------------------------------------------------

# read in map polygons
load('data/processed/tss.rda')
load('data/processed/gis.rda')
load('data/processed/dma.rda')
load('data/processed/sma.rda')

# read in password file
load('data/processed/password.rda')