subsample_gps = function(gps=gps,n=60,plot_comparison=F){
# Subsample aerial gps data frame to only include 1 sample every (n) seconds. If n=0, no subsampling...
  
  if(n>0){
    # determine sample rate
    ts = as.numeric(round(median(diff(gps$time), na.rm = T), 1))
    
    # subsample
    if(ts>0 & n>ts){
      tracks = gps[seq(1, nrow(gps), n/ts),]
    } else {
      # message('No subsampling occured - unable to determine gps sampling rate')
      return(gps)
    }
    
    # compare subsample
    if(plot_comparison){
      source('functions/plot_track.R')
      
      plot_track(gps)
      
      lines(tracks$lon, tracks$lat, col = 'red')
      
      legend('bottomright', lty = c(1,1), col = c('blue', 'red'), cex = .7, bty = 'n',
             legend = c(paste0('Original (', nrow(gps), ' pts, 1 pt every ', ts, ' sec)'),
                        paste0('Subsample (', nrow(tracks), ' pts, 1 pt every ', n, ' sec)')))
    }
    
    return(tracks)
    
  } else {
    
    # message('No subsampling occured - please choose a value >0')
    return(gps)
    
  }
}