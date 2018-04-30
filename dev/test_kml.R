library(plotKML, quietly = T)


# load useful libraries
library(rgdal, quietly = T)
library(xml2)

kmlfile = 'data/raw/2018_whalemapdata/CP_king_air/NFLD_region/Test/AircraftTracks.kml'

# read in xml
x = read_xml(kmlfile)

# explore contents
xml_name(x)
xml_children(x)

# extract location data
at = xml_find_all(x, ".//gx:coord")
str = xml_text(at)
ls = strsplit(str, split = ' ')

lon = as.numeric(sapply(ls, function(x) x[[1]]))
lat = as.numeric(sapply(ls, function(x) x[[2]]))
altitude = as.numeric(sapply(ls, function(x) x[[3]]))

# plot

library(oce)
library(ocedata)
data("coastlineWorldFine")

plot(coastlineWorldFine, 
     clon = mean(lon, na.rm = T), 
     clat = mean(lat, na.rm = T), 
     span = 2000
)

lines(lon, lat, col = 'blue')

# extract time data
at = xml_find_all(x, ".//gx:Track")
at
str = xml_text(at)
ls = strsplit(str, split = ' ')


