## proc_sonobuoys ##
# combine all sonobuoys

# list sonobuoy files
sono_list = list.files('data/interim', pattern = 'sonobuoys', full.names = T)

# read in files
for(i in seq_along(sono_list)){
  
  # get data
  isono = readRDS(sono_list[[i]])
  
  # combine
  if(i==1){
    sono = isono
  } else {
    sono = rbind(sono, isono) # add to list
  }
}

# remove duplicates
sono = sono[which(!duplicated(sono)),]

# save
saveRDS(sono, 'data/processed/sonobuoys.rds')