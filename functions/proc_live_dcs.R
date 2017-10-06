# process and save all live and archived dcs (glider, buoy, etc) deployment tracklines and detections

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/dcs/live/'

# directory for output
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
library(lubridate)
library(sp)
library(reshape2)
source('functions/config_data.R')

# define functions --------------------------------------------------------

insert_NAs = function(d, thresh = 2*60*60){
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

# list detection files (live and archived)
detection_dir_list = list.files(path = data_dir, full.names = T)

detection_list = list()
for(i in seq_along(detection_dir_list)){
  
  # determine deployment directory
  dir = detection_dir_list[[i]]
  
  # read in detection data
  d = read.csv(paste0(dir,'/manual_analysis.csv'))
  
  # remove unneeded columns
  d$analyst = NULL
  d$notes = NULL
  
  # fix time
  d$datetime_utc = as.character(d$datetime_utc)
  d$time = as.POSIXct(d$datetime_utc,format = '%Y%m%d%H%M%S',tz = 'UTC')
  d$datetime_utc = NULL
  
  # configure time
  d$time = format(d$time, tz="UTC",usetz=TRUE)
  d$date = as.Date(d$time)
  d$yday = yday(d$time)
  d$year = year(d$time)
  
  # add deployment metadata
  d$id = paste0(basename(dir), '-live')
  # d$start_date = basename(strsplit(dir, '_')[[1]][1])
  d$platform = strsplit(dir, '_')[[1]][2]
  d$name = strsplit(dir, '_')[[1]][3]
  
  # insert NAs when time threshold is exceeded
  d = insert_NAs(d)
  
  # add to the list
  detection_list[[i]] = d
}

# flatten list
all = do.call(rbind, detection_list)

# convert column types
all$platform = as.factor(all$platform)
all$name = as.factor(all$name)
all$time = as.POSIXct(all$time, tz="UTC")

# convert score names
# sei
all$sei = gsub(all$sei, pattern = 'present', replacement = 'detected')
all$sei = gsub(all$sei, pattern = 'maybe', replacement = 'possibly detected')
all$sei = gsub(all$sei, pattern = 'absent', replacement = 'not detected')
all$sei = as.factor(all$sei)

# fin
all$fin = gsub(all$fin, pattern = 'present', replacement = 'detected')
all$fin = gsub(all$fin, pattern = 'maybe', replacement = 'possibly detected')
all$fin = gsub(all$fin, pattern = 'absent', replacement = 'not detected')
all$fin = as.factor(all$fin)

# right
all$right = gsub(all$right, pattern = 'present', replacement = 'detected')
all$right = gsub(all$right, pattern = 'maybe', replacement = 'possibly detected')
all$right = gsub(all$right, pattern = 'absent', replacement = 'not detected')
all$right = as.factor(all$right)

# humpback
all$humpback = gsub(all$humpback, pattern = 'present', replacement = 'detected')
all$humpback = gsub(all$humpback, pattern = 'maybe', replacement = 'possibly detected')
all$humpback = gsub(all$humpback, pattern = 'absent', replacement = 'not detected')
all$humpback = as.factor(all$humpback)

# drop all unused levels
all = droplevels(all)

# create trackline file ---------------------------------------------------

# remove species info and keep tracklines
tracks = all[,-c(1:4)]

# config data types
tracks = config_tracks(tracks)

# save output
saveRDS(tracks, paste0(output_dir, 'dcs_live_tracks.rds'))

# create latest position file ---------------------------------------------

# split tracks by deployment
dep = split(tracks, tracks$id)

# determnine latest observation from each deployment
latest = lapply(dep, function(x){
  x[nrow(x),]
})

# flatten list
latest = do.call(rbind,latest)

# save output
saveRDS(latest, paste0(output_dir, 'dcs_live_latest_position.rds'))

# create detections file --------------------------------------------------

# convert detections to long form
detections = melt(all, measure.vars = c('right', 'sei', 'fin', 'humpback'), variable.name = 'species', value.name = 'score')

# remove absences to reduce data frame size
detections = detections[detections$score!='not detected',]

# add number column
detections$number = NA

# config data types
detections = config_observations(detections)

# save output
saveRDS(detections, paste0(output_dir, 'dcs_live_detections.rds'))


