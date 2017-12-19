subsample_gps = function(gps,subsample_rate=30,plot_comparison=F){
  
  if(subsample_rate>0){
    # determine sample rate
    ts = as.numeric(round(median(diff(gps$time), na.rm = T), 1))
    
    # subsample
    if(ts>0){
      tracks = gps[seq(1, nrow(gps), subsample_rate/ts),]  
    } else {
      # message('No subsampling occured - unable to determine gps sampling rate')
      return(gps)
    }
    
    # compare subsample
    if(plot_comparison){
      plot(gps$lon, gps$lat, type = 'l', xlab = 'lon', ylab = 'lat')
      lines(tracks$lon, tracks$lat, col = 'blue')
      legend('bottomright', lty = c(1,1), col = c('black', 'blue'), cex = .7, bty = 'n',
             legend = c(paste0('Original (', nrow(gps), ' pts, 1 pt every ', ts, ' sec)'),
                        paste0('Subsample (', nrow(tracks), ' pts, 1 pt every ', subsample_rate, ' sec)')))
    }
    
    return(tracks)
    
  } else {
    
    # message('No subsampling occured - please choose a value >0')
    return(gps)
    
  }
}