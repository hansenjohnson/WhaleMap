sub_dataframe = function(dataframe, n){
  dataframe[(seq(n,to=nrow(dataframe),by=n)),]
}

subsample_gps = function(gps, n=60, tol = 0.001, plot_comparison=F, full_res=F, simplify = TRUE){
  # 'gps' is a data frame that has columns named 'lat' and 'lon' in decimal degrees
  # 'n' is the desired gps sampling interval in seconds (only when simplify=FALSE)
  # 'tol' is a tolerance for simplifying where larger values provide fewer points (only when simplify=TRUE)
  # 'plot_comparison' is a switch to produce a plot of the original and new track
  # 'full_res' is a switch to skip subsampling and maintain full gps resolution
  # 'simplify' is a switch to choose the method for simplifying the tracks. TRUE simplifies with the Douglas-Peuker algorithm (rgeos::gSimplify), and FALSE subsamples the gps to a given time interval
  
  rn = 10 # row subset (take row every n rows)
  
  if(simplify){
    # simplify ----------------------------------------------------------------
    # simplify the geometry using Douglas-Peuker algorithm
    
    suppressPackageStartupMessages(library(sp))
    suppressPackageStartupMessages(library(rgeos))
    
    # return full resolution tracks if desired or if timestamps are not unique
    if(full_res){
      
      # no subsampling
      new = gps
      
    } else if(length(unique(gps$time))<nrow(gps)/2){
      
      # subset rows
      new = sub_dataframe(gps, rn)
      
    } else {
      
      # remove columns without lat or lon
      gps = gps[which(!is.na(gps$lat)),]
      gps = gps[which(!is.na(gps$lon)),]
      
      # create lines object
      ln = Line(cbind(gps$lat, gps$lon))
      
      # convert to Lines
      lns = Lines(ln, ID = 'track')
      
      # convert to Spatial Lines
      slns = SpatialLines(list(lns))
      
      # simplify
      sim = gSimplify(slns, tol = tol)
      
      # # warning if not simple
      # if(!gIsSimple(sim)){
      #   warning('Line is not simple! Duplicates will be removed, but watch for consequences. Consider lowering subset tolerance...')
      # }
      
      # extract coordinates in data frame
      df = as.data.frame(coordinates(sim)[[1]][[1]])
      colnames(df) = c('lat', 'lon')
      
      # match appropriate rows in original data
      new = gps[match(round(df$lon,5),round(gps$lon,5)),]
      
      # remove duplicates
      new = new[which(!duplicated(new)),]
      
      # order by time
      new = new[order(new$time),]
    }
    
  } else {
    # downsample ----------------------------------------------------------------
    # downsample gps to lower sampling rate
    
    # return full resolution tracks if desired
    if(full_res){
      
      # no subsampling
      new=gps
      
    } else if(length(unique(gps$time))<nrow(gps)/2){
      
      # subset rows
      new = sub_dataframe(gps, rn)
      
    }else{      
      # determine sample rate
      ts = as.numeric(round(median(diff(gps$time), na.rm = T), 1))
      
      # subsample
      if(ts>0 & n>ts){
        new = gps[seq(1, nrow(gps), n/ts),]
      } else {
        message('No subsampling occured - unable to determine gps sampling rate')
        new = gps
      }
    }
  }
  
  # plot comparison ---------------------------------------------------------
  if(plot_comparison & !full_res){
    
    # start plot
    png(paste0('figures/track_comparison/', min(gps$time), '.png'), width = 8, height = 5, units = 'in', res = 100)
    
    par(mfrow=c(1,2))
    
    # plot original
    plot(gps$lon, gps$lat, type = 'l', col = 'red', xlab = '', ylab = '',main = 'Original')
    mtext(paste0('Points: ', nrow(gps), ', Size (bytes): ', object.size(gps)), side = 3, adj = 0)
    
    # plot new
    plot(gps$lon, gps$lat, type = 'l', col = 'red', xlab = '', ylab = '',main = 'Subsampled')
    lines(new$lon, new$lat, type = 'l', col = 'blue')
    mtext(paste0('Points: ', nrow(new), ', Size (bytes): ', object.size(new)), side = 3, adj = 0)
    
    dev.off()
  }
  
  # return data
  return(new)
  
}