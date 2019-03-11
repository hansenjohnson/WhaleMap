# read in geojson
t = readRDS('dev/test.rds')

# extract lat lon
lng = sapply(t$features, FUN = function(x) x$geometry$coordinates[[1]])
lat = sapply(t$features, FUN = function(x) x$geometry$coordinates[[2]])
DF = data.frame(lng, lat)

# make a known change
u[2,1] = -60

# rebuild geojson
for(i in 1:nrow(u)){
  t$features[[i]]$geometry$coordinates[[1]] = u[i,1]
  t$features[[i]]$geometry$coordinates[[2]] = u[i,2]
}

# check for change
as.data.frame(t(sapply(t$features, FUN = function(x) x$geometry$coordinates)))

# # build functions
# extract_ll = function(feature, ind){
#   return(unlist(feature$features[[ind]]$geometry$coordinates))
# }
# rebuild_ll = function(feature, ind, lon, lat){
#   feature$features[[ind]]$geometry$coordinates = list(lon,lat)
#   return(feature)
# }
# 
# for(i in 1:nrow(u)){
#   t = rebuild_ll(t, i, u[i,1], u[i,2])
# }