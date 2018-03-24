# simplify shapes

library(sp)
library(rgeos)
library(rgdal)

# load data
tracks = readRDS('data/interim/noaa_twin_otter_tracks.rds')

?rgeos::gSimplify()

# split up data frame to a list of flights
lst = split(tracks, f = tracks$id)

# extract coordinates
lst2 = lapply(lst, function(x) cbind(x$lat, x$lon))

# convert to lines
lns = lapply(lst2, FUN = Line)

# make spatial lines data frame
Lns = Lines(lns, ID = 'noaa')

# Spatial
Slns = SpatialLines(list(Lns))

# simplify
sSlns = gSimplify(Slns, tol = .05)

# compare
plot(Slns)
lines(sSlns, col = 'blue')

# save
saveRDS(Slns, 'noaa_full.rds')
saveRDS(sSlns, 'noaa_simple.rds')
