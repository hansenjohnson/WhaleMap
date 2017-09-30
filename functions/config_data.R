config_tracks = function(tracks){
  
  # configure column types
  tracks$time = as.POSIXct(tracks$time, tz = 'UTC', usetz = T)
  tracks$lat = as.numeric(tracks$lat)
  tracks$lon = as.numeric(tracks$lon)
  tracks$date = as.Date(tracks$date)
  tracks$yday = as.numeric(tracks$yday)
  tracks$year = as.character(tracks$year)
  tracks$platform = as.factor(tracks$platform)
  tracks$name = as.factor(tracks$name)
  tracks$id = as.character(tracks$id)
  
  return(tracks)
}

config_observations = function(obs){
  
  # configure column types
  obs$time = as.POSIXct(obs$time, tz = 'UTC', usetz = T)
  obs$species = as.factor(obs$species)
  obs$lat = as.numeric(obs$lat)
  obs$lon = as.numeric(obs$lon)
  obs$date = as.Date(obs$date)
  obs$yday = as.numeric(obs$yday)
  obs$year = as.character(obs$year)
  obs$platform = as.factor(obs$platform)
  obs$name = as.factor(obs$name)
  obs$id = as.character(obs$id)
  obs$score = as.factor(obs$score)
  obs$number = as.numeric(obs$number)
  
  return(obs)
}