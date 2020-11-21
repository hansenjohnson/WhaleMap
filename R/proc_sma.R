# proc_sma #
# process US Seasonal Management Area

# input -------------------------------------------------------------------

# input directory
gis_dir = 'data/raw/sma/'

# output file
ofile = 'data/processed/sma.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tidyverse))

# common projection
ref = "+proj=longlat +init=epsg:3857"

# process -----------------------------------------------------------------

# read seasonal management data
sma = readOGR(gis_dir) %>%
  spTransform(ref)

# add metadata for active period
sma$active = NA
sma$active[sma$Restr_Area == 'Southeast U.S.'] = 'November 1 - April 15'
sma$active[sma$Restr_Area == 'Mid-Atlantic U.S. (South)'] = 'November 1 - April 30'
sma$active[sma$Restr_Area == 'Mid-Atl Morehead City/Beaufort'] = 'November 1 - April 30'
sma$active[sma$Restr_Area == 'Mid-Atl Chesapeake Bay'] = 'November 1 - April 30'
sma$active[sma$Restr_Area == 'Mid-Atl Delaware Bay'] = 'November 1 - April 30'
sma$active[sma$Restr_Area == 'Mid-Atl New York/New Jersey'] = 'November 1 - April 30'
sma$active[sma$Restr_Area == 'Mid-Atl Block Island Sound'] = 'November 1 - April 30'
sma$active[sma$Restr_Area == 'NE U.S. Great South Channel'] = 'April 1 - July 31'
sma$active[sma$Restr_Area == 'NE U.S. Off Race Point'] = 'March 1 - April 30'
sma$active[sma$Restr_Area == 'NE U.S. Cape Cod Bay'] = 'January 1 - May 15'

# test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('sma')
#     ) %>%
#   addPolygons(data = sma, color = 'brown', popup = ~paste0(ID,'<br>',Restr_Area,'<br>',active),
#                group = 'sma',weight = 2)

# save
save(sma, file = ofile)
