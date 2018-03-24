
assign_groups = function(all){
  
  # add column to hold output
  all$group = NA
  
  # determine positions of NAs
  na_list = which(is.na(all$lat))
  
  # loop through and assign ids to groups between NAs
  j=1
  for(i in 1:(length(na_list)-1)){
    s = na_list[i]
    e = na_list[i+1]
    
    if((e-s)>1){
      all$group[s:e] = j
      j=j+1
    }
  }
  
  # remove NAs
  fin = all[!is.na(all$lon),]
  
  # convert to factor
  fin$group = as.factor(fin$group)
  
  # split by factor into list of data frames
  sf = split(fin, fin$group)
  
  # add NA row to each 
  lst = lapply(sf, function(x) rbind(x, rep(NA,ncol(fin))))
  
  # flatten list of data frames
  out = do.call(rbind, lst)
  
  return(out)
}

