plot_track = function(gps, span = 'default', verbose = F){
  library(oce)
  library(ocedata)
  data("coastlineWorldFine")
  
  if(span=='default'){
    span = 3 * 111 * diff(range(gps$lat))
    if(verbose){
      message('Using span = ', span)
    }
  }
  
  plot(coastlineWorldFine, 
       clon = mean(gps$lon), 
       clat = mean(gps$lat), 
       span = span
  )
  
  lines(gps$lon, gps$lat, col = 'blue')
}