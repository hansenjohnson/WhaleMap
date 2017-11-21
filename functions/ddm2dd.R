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


