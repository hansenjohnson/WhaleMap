# proc_sma #
# process US Seasonal Management Area

# input -------------------------------------------------------------------

# input directory
gis_dir = 'data/raw/gis/sma/'

# output file
ofile = 'data/processed/sma.rda'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))
source('R/functions.R')

# common projection
ref = "+proj=longlat +init=epsg:3857"

# system time
sdate = as.Date(with_tz(Sys.time(), tzone = 'America/New_York'))
syday = yday(sdate)
extra_day = ifelse(leap_year(sdate),1,0)

# process -----------------------------------------------------------------

# read seasonal management data
sma = readOGR(gis_dir) %>%
  spTransform(ref)

# add metadata for active period
sma$start = sdate
sma$end = sdate
sma$start[sma$Restr_Area == 'Southeast U.S.'] = as.Date('2020-11-01')
sma$end[sma$Restr_Area == 'Southeast U.S.'] = as.Date('2021-04-15')
sma$start[sma$Restr_Area == 'Mid-Atlantic U.S. (South)'] = as.Date('2020-11-01')
sma$end[sma$Restr_Area == 'Mid-Atlantic U.S. (South)'] = as.Date('2021-04-30')
sma$start[sma$Restr_Area == 'Mid-Atl Morehead City/Beaufort'] = as.Date('2020-11-01')
sma$end[sma$Restr_Area == 'Mid-Atl Morehead City/Beaufort'] = as.Date('2021-04-30')
sma$start[sma$Restr_Area == 'Mid-Atl Chesapeake Bay'] = as.Date('2020-11-01')
sma$end[sma$Restr_Area == 'Mid-Atl Chesapeake Bay'] = as.Date('2021-04-30')
sma$start[sma$Restr_Area == 'Mid-Atl Delaware Bay'] = as.Date('2020-11-01')
sma$end[sma$Restr_Area == 'Mid-Atl Delaware Bay'] = as.Date('2021-04-30')
sma$start[sma$Restr_Area == 'Mid-Atl New York/New Jersey'] = as.Date('2020-11-01')
sma$end[sma$Restr_Area == 'Mid-Atl New York/New Jersey'] = as.Date('2021-04-30')
sma$start[sma$Restr_Area == 'Mid-Atl Block Island Sound'] = as.Date('2020-11-01')
sma$end[sma$Restr_Area == 'Mid-Atl Block Island Sound'] = as.Date('2021-04-30')
sma$start[sma$Restr_Area == 'NE U.S. Great South Channel'] = as.Date('2021-04-01')
sma$end[sma$Restr_Area == 'NE U.S. Great South Channel'] = as.Date('2021-07-31')
sma$start[sma$Restr_Area == 'NE U.S. Off Race Point'] = as.Date('2021-03-01')
sma$end[sma$Restr_Area == 'NE U.S. Off Race Point'] = as.Date('2021-04-30')
sma$start[sma$Restr_Area == 'NE U.S. Cape Cod Bay'] = as.Date('2021-01-01')
sma$end[sma$Restr_Area == 'NE U.S. Cape Cod Bay'] = as.Date('2021-05-15')

# add label
sma$active = paste0(format(sma$start, '%b %d'), ' - ', format(sma$end, '%b %d'))

# determine which are active
sma$plot = FALSE
for(ii in seq_along(sma$start)){
  sma$plot[ii] = syday %in% (yday(seq.Date(from = sma$start[ii], to = sma$end[ii], by = 'day')) + extra_day)
}

# restrict to active
sma = sma[sma$plot == TRUE,]

# save
save(sma, file = ofile)

# # test with leaflet
# library(leaflet)
# leaflet() %>%
#   addTiles() %>%
#   addLayersControl(
#     overlayGroups = c('sma')
#     ) %>%
#   addPolygons(data = sma, color = 'brown', popup = ~paste0(ID,'<br>',Restr_Area,'<br>',active),
#                group = 'sma',weight = 2)
