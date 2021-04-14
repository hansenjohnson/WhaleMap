# proc_boem #
# process energy development areas from BOEM

# input -------------------------------------------------------------------

# input directory
gis_dir = 'data/raw/boem/'

# output directory
output_dir = 'data/processed/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(rgeos))

# common projection
ref = "+proj=longlat +init=epsg:3857"

# process -----------------------------------------------------------------

# read ny zone
ny = readOGR(paste0(gis_dir, '/NY WEAs_new as of 3_29_21/')) %>%
  spTransform(ref)

# add metadata
ny@data$ID = 'NY Wind Energy Area'
ny@data$Id = NULL

# read project areas
pj = readOGR(paste0(gis_dir, '/Project Areas/')) %>%
  spTransform(ref)

# add metadata
pj@data$ID = paste0('Project area: ', pj@data$NAME)
pj@data$NAME = NULL
pj@data$Acres = NULL

# combine
boem = rbind(ny, pj)

# test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('boem')
#     ) %>%
#   addPolygons(data = boem, color = 'blue', popup = ~paste0(ID),
#                group = 'boem',weight = 2)

# save
save(boem, file = paste0(output_dir, 'boem.rda'))
