plot_track = function(gps){
  library(oce)
  library(ocedata)
  data("coastlineWorldFine")
  
  plot(coastlineWorldFine, 
       clon = mean(gps$lon), 
       clat = mean(gps$lat), 
       span = 3 * 111 * diff(range(gps$lat))
  )
  
  lines(gps$lon, gps$lat, col = 'blue')
}