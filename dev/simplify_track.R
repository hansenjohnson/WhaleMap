simplify_track = function(orig, tol = 0.0075, plot_comparison=F){
  # 'orig' is a data frame that has with columns 'lat' and 'lon' in decimal degrees
  # 'tol' is a tolerance for subsampling, where larger values provides coarser resolution (fewer points)
  library(sp)
  library(rgeos)
  
  # create lines object
  ln = Line(cbind(orig$lat, orig$lon))
  
  # convert to Lines
  lns = Lines(ln, ID = 'track')
  
  # convert to Spatial Lines
  slns = SpatialLines(list(lns))
  
  # simplify
  sim = gSimplify(slns, tol = tol)
  
  # extract coordinates in data frame
  df = as.data.frame(coordinates(sim)[[1]][[1]])
  colnames(df) = c('lat', 'lon')
  
  # match appropriate rows in original data
  new = orig[match(round(df$lon,5),round(orig$lon,5)),]
  
  # plot comparison
  if(plot_comparison){
    par(mfrow=c(1,2))
    
    # plot original
    plot(orig$lon, orig$lat, type = 'l', col = 'red', xlab = '', ylab = '',main = 'Original')
    mtext(paste0('Points: ', nrow(orig), ', Size (bytes): ', object.size(orig)), side = 3, adj = 0)
    
    # plot new
    plot(orig$lon, orig$lat, type = 'l', col = 'red', xlab = '', ylab = '',main = 'Subsampled')
    lines(new$lon, new$lat, type = 'l', col = 'blue')
    mtext(paste0('Points: ', nrow(new), ', Size (bytes): ', object.size(new)), side = 3, adj = 0)
  }
  
  return(new)
}