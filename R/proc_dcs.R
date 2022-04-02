# dcs processing function

proc_dcs = function(data_dir, output_dir, det_fname, track_fname, ext = ""){

  # setup -------------------------------------------------------------------
  
  # libraries
  suppressPackageStartupMessages(library(tidyverse))
  suppressPackageStartupMessages(library(lubridate))
  suppressPackageStartupMessages(library(sp))
  suppressPackageStartupMessages(library(reshape2))
  source('R/functions.R')
  
  # list names of potential input species
  species_list = c('right', 'fin', 'sei', 'humpback', 'blue')
  
  # define functions --------------------------------------------------------
  
  insert_NAs = function(d, thresh = 4*60*60){
    # insert an NA into the data frame when the time between observations exceeds a threshold
    
    # create time vector
    t = as.POSIXct(d$time, tz = 'UTC')
    
    # align times to calculate difference
    t0 = t[1:length(t)-1]
    t1 = t[2:length(t)]
    
    # find rows where the time difference exceeds the threshold
    ind = which(abs(difftime(t0, t1))>thresh)
    
    # return if threshold is not exceeded
    if(length(ind)==0){return(d)}
    
    # define rows of NAs to insert
    NArow = d[ind,]
    NArow$lat = NA
    NArow$lon = NA
    #NArow$time = as.POSIXct(NArow$time) + thresh
    
    # loop to make NA insertions
    c = 0 # initialize counter
    for(i in 1:length(ind)){
      # find index, correcting for growing data frame because of other insertions
      id = ind[i]+c 
      
      # insert row
      d = rbind(d[1:id,],NArow[i,],d[-(1:id),])  
      
      # add to counter
      c = c+1
    }
    
    return(d)
  }
  
  # process data ------------------------------------------------------------
  
  # list detection files
  flist = list.files(path = data_dir, full.names = T)
  
  # return if there are no files
  if(length(flist)==0){
    return()
  }
  
  # empty lists for detections and tracks
  DET = list()
  TRK = list()
  
  # process each file
  for(i in seq_along(flist)){
    
    # determine deployment directory
    dir = flist[[i]]
    
    # read in detection data
    ifile = paste0(dir,'/manual_analysis.csv')
    if(file.exists(ifile)){
      tmp = read.csv(ifile, stringsAsFactors = FALSE)  
    } else {
      message('Cannot find ', ifile, '! Skipping...') 
      next
    }
    
    # remove unneeded columns
    tmp$analyst = NULL
    tmp$notes = NULL
    
    # fix time
    tmp$datetime_utc = as.character(tmp$datetime_utc)
    tmp$time = as.POSIXct(tmp$datetime_utc,format = '%Y%m%d%H%M%S',tz = 'UTC')
    tmp$datetime_utc = NULL
    
    # configure time
    tmp$time = format(tmp$time, tz="UTC",usetz=TRUE)
    tmp$date = as.Date(tmp$time)
    tmp$yday = yday(tmp$time)
    tmp$year = year(tmp$time)
    
    # add deployment metadata
    tmp$id = paste0(basename(dir), ext)
    tmp$platform = strsplit(dir, '_')[[1]][2]
    tmp$name = strsplit(dir, '_')[[1]][3]
    
    # insert NAs when time threshold is exceeded
    tmp = insert_NAs(tmp)
    
    # make trackline file
    TRK[[i]] = tmp[!colnames(tmp) %in% species_list]
    
    # create single species column
    tmpl = melt(tmp, 
               measure.vars = species_list[species_list %in% colnames(tmp)], 
               variable.name = 'species', 
               value.name = 'score')
    
    # rename factor levels for score
    tmpl$score = gsub(tmpl$score, pattern = 'absent', replacement = 'not detected')
    tmpl$score = gsub(tmpl$score, pattern = 'maybe', replacement = 'possibly detected')
    tmpl$score = gsub(tmpl$score, pattern = 'present', replacement = 'detected')
    tmpl$score = as.factor(tmpl$score)
    
    # add to the list
    DET[[i]] = tmpl
  }
  
  # create trackline file ---------------------------------------------------
  
  # flatten list
  tracks = suppressWarnings(bind_rows(TRK))
  
  # sort by time (important for plotting)
  tracks = tracks[order(tracks$id, tracks$time),]
  
  # config data types
  tracks = config_tracks(tracks)
  
  # save output
  saveRDS(tracks, paste0(output_dir, track_fname))
  
  # create detections file --------------------------------------------------
  
  # flatten list
  detections = suppressWarnings(bind_rows(DET))
  
  # remove absences to reduce data frame size
  detections = detections[detections$score!='not detected',]
  
  # add number and calve column
  detections$number = NA
  detections$calves = NA
  
  # config data types
  detections = config_observations(detections)
  
  # drop all unused levels
  detections = droplevels(detections)
  
  # save output
  saveRDS(detections, paste0(output_dir, det_fname))
  
}

