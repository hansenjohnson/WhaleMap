# simplify shapes

library(sp)
library(rgeos)
library(rgdal)

# load data
tracks = readRDS('data/interim/2017_tc_dash8_tracks.rds')

# ?rgeos::gSimplify()

# split up data frame to a list of flights
lst = split(tracks, f = tracks$id)

# extract coordinates
lst2 = lapply(lst, function(x) cbind(x$lat, x$lon))

# convert to lines
lns = lapply(lst2, FUN = Line)

# make spatial lines data frame
Lns = Lines(lns, ID = 'test')

# convert to spatial lines object
Slns = SpatialLines(list(Lns))

# simply and plot ---------------------------------------------------------

par(mfrow=c(2,2))

# original
plot(Slns, main = paste0('Original (', object.size(Slns), ' bytes)'))

# 1
t1 = gSimplify(Slns, tol = .05)
plot(t1, main = paste0('Tol: 0.05 (', object.size(t1), ' bytes)'))

# 2
t2 = gSimplify(Slns, tol = .1)
plot(t2, main = paste0('Tol: 0.1 (', object.size(t2), ' bytes)'))

# 3
t3 = gSimplify(Slns, tol = .5)
plot(t3, main = paste0('Tol: 0.5 (', object.size(t3), ' bytes)'))

coordinates(t3)

# convert back to lines ---------------------------------------------------

df <- data.frame(len = sapply(1:length(Slns), function(i) gLength(Slns[i, ])))

Sldf <- SpatialLinesDataFrame(Slns, data = df)
