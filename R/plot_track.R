plot_track = function(gps, span = 'default', verbose = F){
  suppressPackageStartupMessages(library(oce))
  suppressPackageStartupMessages(library(ocedata))
  data("coastlineWorldFine")
  
  # determine limits
  if(span=='default'){
    # span = 3 * 111 * diff(range(gps$lat, na.rm = T))
    span = 6 * 111 * diff(range(gps$lat, na.rm = T))
    if(verbose){
      message('Using span = ', span)
    }
  }
  
  # make map
  plot(coastlineWorldFine, 
       clon = mean(gps$lon, na.rm = T), 
       clat = mean(gps$lat, na.rm = T), 
       span = span
  )
  
  # add lines
  lines(gps$lon, gps$lat, col = 'blue')
}