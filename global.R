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
source('R/functions.R')

# definitions -------------------------------------------------------------

# define color palette list to choose from
palette_list = list(heat.colors(200), 
                    oce.colorsTemperature(200),
                    oce.colorsSalinity(200),
                    oce.colorsDensity(200),
                    oce.colorsChlorophyll(200),
                    oce.colorsGebco(200),
                    oce.colorsJet(200),
                    oceColorsViridis(200))

# define score colors
score_cols = c('definite acoustic' = 'red', 
               'possible acoustic' = 'yellow', 
               'definite visual' = 'darkslategray',
               'possible visual' = 'gray')

# define visual and acoustic platforms
visual_platforms = c('plane', 'vessel')
acoustic_platforms = c('slocum', 'buoy', 'wave')

# define track point plotting threshold
npts = 250000

# define time lag for startup plotting
tlag = 14 # days

# define year choices for ui input
years = c('2014', '2015', '2016', '2017', '2018', '2019')

# make dcs icons
dcsIcons = iconList(
  slocum = makeIcon("icons/slocum.png", iconWidth = 40, iconHeight = 40),
  wave = makeIcon("icons/wave.png", iconWidth = 35, iconHeight = 30),
  buoy = makeIcon("icons/buoy.png", iconWidth = 50, iconHeight = 40)
)

# make sono icon
sonoIcon = makeIcon("icons/sono.png", iconWidth = 10, iconHeight = 45)

# load data ---------------------------------------------------------------

# read in map polygons
mpa = readRDS('data/processed/mpa.rds')
load('data/processed/tss.rda')
# load('data/processed/management_areas.rda')
load('data/processed/gis.rda')

# read in password file
load('data/processed/password.rda')