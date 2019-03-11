# quick script to add st anne's bank mpa to mpa list

# libraries
library(rgdal)
library(ggmap)
library(leaflet)

# read in data
sab = readOGR('data/raw/mpa/SAB_boundary_zones_2017/')

# test shapefile
leaflet() %>%
  addTiles() %>%
  addPolygons(data = sab)

# convert to data frame
sb = fortify(sab)

# separate polygons with NAs
sb0 = sb[sb$id == 0,]
sb1 = sb[sb$id == 1,]
sb2 = sb[sb$id == 2,]
sb3 = sb[sb$id == 3,]
sbb = rbind(sb0,NA,sb1,NA, sb2, NA, sb3)

# add important info
df = data.frame(lon = sbb$long, lat = sbb$lat, name = 'St Anne\'s Bank Marine Protected Area', type = 'polygons')

# make rows na
df$name[is.na(df$lon)] = NA
df$type[is.na(df$lon)] = NA

# test
leaflet() %>%
  addTiles() %>%
  addPolygons(lat = df$lat, lng = df$lon)

# add to mpa file
mpa = read.csv('data/raw/mpa/mpa.csv')
mpa = mpa[mpa$name != 'St Anne\'s Bank Marine Protected Area',]
mpa = rbind(mpa, df)

# test all
leaflet() %>%
  addTiles() %>%
  addPolygons(lat = mpa$lat, lng = mpa$lon)

# overwrite csv file with new data
write.csv(x = mpa, file = 'data/raw/mpa/mpa.csv', row.names = FALSE)
