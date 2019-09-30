## functions ##

suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(RColorBrewer))

clean_latlon = function(d){
  d$lat = as.character(d$lat)
  d$lat = gsub(",","",d$lat)
  d$lat = d$lat = gsub("^\\s","",d$lat)
  d$lat = as.numeric(d$lat)
  
  d$lon = as.character(d$lon)
  d$lon = gsub(",","",d$lon)
  d$lon = d$lon = gsub("^\\s","",d$lon)
  d$lon = as.numeric(d$lon)
  
  d$lon[which(d$lon>0)] = -d$lon[which(d$lon>0)]
  
  return(d)
}

config_tracks = function(tracks){
  
  # list required column names
  columns = c('time',
              'lat',
              'lon',
              'speed',
              'altitude',
              'date',
              'yday',
              'year',
              'platform',
              'name',
              'id')
  
  # return blank table if input is empty
  if(nrow(tracks)==0){
    tracks = data.frame(matrix(nrow = 0, ncol = length(columns)))
    colnames(tracks) = columns
    return(tracks)
  }
  
  # configure column types
  if(is.null(tracks$time)){tracks$time = NA}
  tracks$time = as.POSIXct(tracks$time, tz = 'UTC', usetz = T)
  
  if(is.null(tracks$lat)){tracks$lat = NA}
  tracks$lat = as.numeric(tracks$lat)
  
  if(is.null(tracks$lon)){tracks$lon = NA}
  tracks$lon = as.numeric(tracks$lon)
  
  if(is.null(tracks$speed)){tracks$speed = NA}
  tracks$speed = as.numeric(tracks$speed)
  
  if(is.null(tracks$altitude)){tracks$altitude = NA}
  tracks$altitude = as.numeric(tracks$altitude)
  
  if(is.null(tracks$date)){tracks$date = NA}
  tracks$date = as.Date(tracks$date)
  
  if(is.null(tracks$yday)){tracks$yday = NA}
  tracks$yday = as.numeric(tracks$yday)
  
  if(is.null(tracks$year)){tracks$year = NA}
  tracks$year = as.numeric(tracks$year)
  
  if(is.null(tracks$platform)){tracks$platform = NA}
  tracks$platform = as.factor(tracks$platform)
  
  if(is.null(tracks$name)){tracks$name = NA}
  tracks$name = as.factor(tracks$name)
  
  if(is.null(tracks$id)){tracks$id = NA}
  tracks$id = as.character(tracks$id)
  
  # re-order
  tracks = tracks[c(columns)]
  
  return(tracks)
}

config_observations = function(obs){
  
  # list required column names
  columns = c('time',
              'lat',
              'lon',
              'date', 
              'yday',
              'species',
              'score',
              'number',
              'calves',
              'year',
              'platform',
              'name',
              'id')
  
  # return blank table if input is empty
  if(nrow(obs)==0){
    obs = data.frame(matrix(nrow = 0, ncol = length(columns)))
    colnames(obs) = columns
    return(obs)
  }
  
  # configure column types
  if(is.null(obs$time)){obs$time = NA}
  obs$time = as.POSIXct(obs$time, tz = 'UTC', usetz = T, origin = '1970-01-01')
  
  if(is.null(obs$species)){obs$species = NA}
  obs$species = as.factor(obs$species)
  
  if(is.null(obs$lat)){obs$lat = NA}
  obs$lat = as.numeric(obs$lat)
  
  if(is.null(obs$lon)){obs$lon = NA}
  obs$lon = as.numeric(obs$lon)
  
  if(is.null(obs$date)){obs$date = NA}
  obs$date = as.Date(obs$date)
  
  if(is.null(obs$yday)){obs$yday = NA}
  obs$yday = as.numeric(obs$yday)
  
  if(is.null(obs$year)){obs$year = NA}
  obs$year = as.numeric(obs$year)
  
  if(is.null(obs$platform)){obs$platform = NA}
  obs$platform = as.factor(obs$platform)
  
  if(is.null(obs$name)){obs$name = NA}
  obs$name = as.factor(obs$name)
  
  if(is.null(obs$id)){obs$id = NA}
  obs$id = as.character(obs$id)
  
  if(is.null(obs$score)){obs$score = NA}
  obs$score = as.factor(obs$score)
  
  if(is.null(obs$number)){obs$number = NA}
  obs$number = as.numeric(obs$number)
  
  if(is.null(obs$calves)){obs$calves = NA}
  obs$calves = as.numeric(obs$calves)
  
  # re-order
  obs = obs[c(columns)]
  
  return(obs)
}

# convert degrees decimal minutes to decimal degrees
ddm2dd = function(DDM){
  ddm = as.character(DDM)
  ddm = strsplit(DDM, split = ' ')
  lat_deg = as.numeric(unlist(ddm)[1])
  lat_min = as.numeric(unlist(ddm)[2])
  lon_deg = as.numeric(unlist(ddm)[3])
  lon_min = as.numeric(unlist(ddm)[4])
  
  if(lat_deg<1){
    lat_dd = lat_deg-lat_min/60
  } else {
    lat_dd = lat_deg+lat_min/60
  }
  
  if(lon_deg<1){
    lon_dd = lon_deg-lon_min/60
  } else {
    lon_dd = lon_deg+lon_min/60
  }
  
  dd = c(lat_dd, lon_dd)
  
  return(dd)
}

get_palette = function(pal = 'Viridis', n = 200){
  ## get a given color palette, pal, of a specific length, n
  
  if(pal == 'Default'){
    pal = 'Viridis'
  }
  
  switch(pal,
         "Viridis" = oce.colorsViridis(n),
         "Heat" = heat.colors(n),
         "Jet" = oce.colorsJet(n),
         "Spectral" = brewer.pal(n, 'Spectral'),
         "Greys" = brewer.pal(n, 'Greys'),
         "Set1" = brewer.pal(n, 'Set1'),
         "Set2" = brewer.pal(n, 'Set2'),
         "Dark" = brewer.pal(n, 'Dark2'),
         "RedBlue" = brewer.pal(n, 'RdBu'),
         "RedYellowBlue" = brewer.pal(n, 'RdYlBu'),
         "Paired" = brewer.pal(n, 'Paired'),
         "Accent" = brewer.pal(n, 'Accent')
  )
}

make_status_table = function(status_file='data/processed/status.txt', 
                             index_file='data/processed/status_index.csv'){
  ## make table to show status of platform data processing
  
  # read in status list
  stl = read.csv(file = status_file, header = FALSE, stringsAsFactors = FALSE)
  
  # rename columns
  colnames(stl) = c('script', 'status')
  
  # trim white space
  stl$status = trimws(stl$status)
  
  # read in index table
  tab = read.csv(file = index_file, header = TRUE)
  
  # return indices of matching index and status files
  ind = match(tab$script, stl$script)
  
  # make data frame
  out = data.frame(
    platform = paste0("<a href='",tab$url, "' target='_blank'>",tab$name,"</a>"),
    status = as.character(stl$status[ind])
  )
  
  # sort with last updated at top
  out = out[order(out$status, decreasing = TRUE),]
  
  # adjust column names
  colnames(out) = c('Platform', 'Last processed [UTC]')
  
  return(out)
}

on_server = function(){
  # simple test to determine if app is running from server
  Sys.info()[['sysname']] == "Linux"
}

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

plot_save_track = function(tracks, file){

  trk_file = paste0(file_path_sans_ext(file), '.png')
  trk_file = gsub(x = trk_file, pattern = '/', replacement = '_')
  trk_file = gsub(x = trk_file, pattern = 'data_raw_',replacement = 'figures/tracks/')
  
  # create output directory
  if(!dir.exists(dirname(trk_file))) dir.create(dirname(trk_file), recursive = T)
  
  # save file
  png(trk_file, width = 5, height = 5, units = 'in', res = 100)
  plot_track(tracks)
  mtext(file, side = 3, adj = 0, cex = 0.6)
  dev.off()
}

roundTen = function(x){
  # simple power 10 rounding function
  10^floor(log10(x))
}

sub_dataframe = function(dataframe, n){
  # subsample rows of a data frame by n
  dataframe[(seq(n,to=nrow(dataframe),by=n)),]
}

subsample_gps = function(gps, n=60, tol = 0.001, plot_comparison=FALSE, full_res=FALSE, simplify = TRUE){
  # 'gps' is a data frame that has columns named 'lat' and 'lon' in decimal degrees
  # 'n' is the desired gps sampling interval in seconds (only when simplify=FALSE)
  # 'tol' is a tolerance for simplifying where larger values provide fewer points (only when simplify=TRUE)
  # 'plot_comparison' is a switch to produce a plot of the original and new track
  # 'full_res' is a switch to skip subsampling and maintain full gps resolution
  # 'simplify' is a switch to choose the method for simplifying the tracks. TRUE simplifies with the Douglas-Peuker algorithm (rgeos::gSimplify), and FALSE subsamples the gps to a given time interval
  
  rn = 10 # row subset (take row every n rows)
  
  if(simplify){
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
  
  # plot comparison
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

subset_canadian = function(df, 
                           crs_string = "+init=epsg:3857", 
                           bb_file = 'data/raw/gis/canadian_boundary/canadian_boundary.csv'){
  
  # catch and return empty input data
  if(nrow(df)==0){
    return(df)
  }
  
  # read
  bb = read.csv(bb_file)
  
  # coordinate reference
  crs_ref = st_crs(crs_string)
  
  # convert to polygon and create sfc
  can = st_sfc(st_polygon(list(as.matrix(bb))), crs = crs_ref)
  
  # convert to spatial features
  df_sf = st_as_sf(df, coords = c("lon", "lat"), crs = crs_ref, agr = "constant", remove = FALSE)
  
  # spatial subsets
  df_in = st_within(x = df_sf, y = can, sparse = FALSE, prepared = FALSE)[,1]
  df_can = df_sf[df_in,]
  
  # convert back to data.frame
  out = as.data.frame(df_can)
  out$geometry = NULL
  
  return(out)
}

find_latest = function(infile, remove_old = TRUE){
# find latest track position  
  
  # read in data
  tracks = readRDS(infile)
  
  # remove NAs
  tracks = tracks[!is.na(tracks$lat),]
  
  # split tracks by deployment
  dep = split(tracks, tracks$id)
  
  # determine latest observation from each deployment
  latest = lapply(dep, function(x){
    x[nrow(x),]
  })
  
  # flatten list
  latest = do.call(rbind,latest)
  
  # remove positions more than 2 weeks old
  if(remove_old){
    # find platforms
    old = which(abs(as.numeric(latest$date) - as.numeric(Sys.Date())) > 14)
    if(length(old)>0){
      # print warning
      message("Removing ", length(old), " platform(s) from live DCS list because their latest reported positions are more than 14 days old. The platform(s) ids are:\n", paste(latest$id[old], collapse = '\n'))
      # remove
      latest = latest[-c(old),]
    }
  }
  
  return(latest)
}
