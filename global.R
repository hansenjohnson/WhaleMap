# global.R
# WhaleMap - a Shiny app for visualizing whale survey data


# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(leaflet))
# suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(htmltools))
suppressPackageStartupMessages(library(htmlwidgets))
# suppressPackageStartupMessages(library(maptools))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(oce))
suppressPackageStartupMessages(library(shinydashboard))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(plotly))
suppressPackageStartupMessages(library(leaflet.extras))
# used for WebGL-accelerated rendering of the track layer (leafgl wraps
# Leaflet.glify); see the track observer in server.R and leafglOutput("map")
# in ui.R. (Observation points were reverted to standard leaflet rendering -
# addCircleMarkers - so this is only needed for tracks now.)
suppressPackageStartupMessages(library(leafgl))
# used in server.R to batch many separate track polylines into a single
# addPolylines() call (one sf LINESTRING feature per track) instead of one
# proxy call per track - see the track observer in server.R
suppressPackageStartupMessages(library(sf))
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
  'rpas' = 'purple',
  'buoy' = 'green4'
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
  'Deployment' = 'id',
  'Data source' = 'source')

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
npts = 500000

# define time lag for startup plotting
tlag = 14 # days
cyear = year(Sys.Date()) # current year

# make dcs icons
dcsIcons = iconList(
  slocum = makeIcon("icons/slocum.png", iconWidth = 38, iconHeight = 38),
  wave = makeIcon("icons/wave.png", iconWidth = 35, iconHeight = 30),
  buoy = makeIcon("icons/buoy.png", iconWidth = 44, iconHeight = 34, iconAnchorX = 22, iconAnchorY = 28)
)

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
hidden_platforms = c('cp_king_air', 'jasco_test', 'jasco-unmanned-sp48')

# load static data ---------------------------------------------------------
# (data that does not change while the app is running - loaded once at
#  app startup and shared across all sessions)

# read in static map polygons
load('data/processed/tss.rda')
load('data/processed/gis.rda')
load('data/processed/boem.rda')
load('data/processed/spd.rda')

# read in platform names
load('data/processed/names.rda')

# read in password file
load('data/processed/password.rda')

# load live data (auto-refreshing) ------------------------------------------
# these files are overwritten by a cron job every ~15 min. reactivePoll /
# reactiveFileReader with session = NULL creates a single, APPLICATION-WIDE
# reactive data source: the file's mtime is checked on the interval below,
# and the (potentially expensive) read function only runs again if the file
# has actually changed. Because session = NULL, this poll happens once for
# the whole app, not once per connected user, and every session automatically
# sees the latest data without needing to reload or restart the app.

# how often to check whether the underlying files have changed (ms)
poll_interval = 5 * 60 * 1000 # 5 minutes

# helper to load a single named object out of an .rda file
load_rda_object = function(path, objname){
  e = new.env()
  load(path, envir = e)
  get(objname, envir = e)
}

# tracklines
get_tracks = reactiveFileReader(
  intervalMillis = poll_interval,
  session = NULL,
  filePath = 'data/processed/effort.rds',
  readFunc = readRDS
)

# sightings / detections
get_observations = reactiveFileReader(
  intervalMillis = poll_interval,
  session = NULL,
  filePath = 'data/processed/observations.rds',
  readFunc = readRDS
)

# latest dcs positions (file may not exist on all deployments)
lfile = 'data/processed/dcs_live_latest_position.rds'
if(file.exists(lfile)){
  get_latest = reactiveFileReader(
    intervalMillis = poll_interval,
    session = NULL,
    filePath = lfile,
    readFunc = readRDS
  )
}

# dynamic management area polygons
get_dma = reactivePoll(
  intervalMillis = poll_interval,
  session = NULL,
  checkFunc = function() file.info('data/processed/dma.rda')$mtime,
  valueFunc = function() load_rda_object('data/processed/dma.rda', 'dma')
)

# seasonal management area polygons
get_sma = reactivePoll(
  intervalMillis = poll_interval,
  session = NULL,
  checkFunc = function() file.info('data/processed/sma.rda')$mtime,
  valueFunc = function() load_rda_object('data/processed/sma.rda', 'sma')
)