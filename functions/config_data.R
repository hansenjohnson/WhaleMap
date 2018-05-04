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

  # # test column names
  # test = columns %in% colnames(tracks)
  # 
  # if(FALSE %in% test){
  #   ind = which(!columns %in% colnames(tracks))
  #   stop('No column(s) called ', paste(as.character(columns[ind]), collapse = " or ") , '!')
  # }
  
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
  
  # # test column names
  # test = columns %in% colnames(obs)
  # 
  # if(FALSE %in% test){
  #   ind = which(!columns %in% colnames(obs))
  #   stop('No column(s) called ', paste(as.character(columns[ind]), collapse = " or ") , '!')
  # }
  
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
  
  # re-order
  obs = obs[c(columns)]
  
  return(obs)
}