## proc_neaq_aerial ##
# process and save all neaq aerial sightings and tracklines

# input -------------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/neaq/aerial/'

# outputs
trk_ofile = 'data/interim/neaq_aerial_eff.rds'
obs_ofile = 'data/interim/neaq_aerial_obs.rds'

# setup -------------------------------------------------------------------

# read in helper functions
source('R/functions.R')

# define species codes
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'SEWH', 'HUWH', 'BLWH'),
  species = c('fin', 'right', 'sei', 'humpback', 'blue'))

# process -----------------------------------------------------------------

# list data files
flist = list.files(data_dir, pattern = '\\d{8}_*.*.csv$',ignore.case = T, full.names = T, recursive = T)
blist = toupper(basename(flist))

# identify unique dates
dates = unique(substr(blist,1,8))

TRK = SIG = vector('list', length = length(dates))
for(ii in seq_along(dates)){
  
  # construct file names
  rfile = paste0(dates[ii],'_RAW.CSV')
  pfile = paste0(dates[ii],'_URI.CSV')
  
  # read in data
  if(pfile %in% blist){
    tmp = read.csv(flist[which(pfile == blist)])
    ifile=pfile
  } else if(rfile %in% blist){
    tmp = read.csv(flist[which(rfile == blist)])
    ifile=rfile
  } else {
    message('No file found for ',dates[ii])
    next
  }
  
  # wrangle time
  tmp$time = as.POSIXct(
    paste0(tmp$year,'-',tmp$month,'-',tmp$day,' ',sprintf('%06d', tmp$time)),
    format = '%Y-%m-%d %H%M%S', tz = 'America/New_York')
  tmp$time = with_tz(tmp$time, tzone = 'UTC')
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  
  # warning for time failure
  if(TRUE %in% is.na(tmp$time)){
    message('NA detected in timestamps of file ', ifile)
  }
  
  # add deployment metadata
  tmp$platform = 'plane'
  tmp$name = 'neaq'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # tracklines --------------------------------------------------------------
  
  # restrict to on effort segments
  # itrk = tmp[tmp$legtype == 2,]
  itrk = tmp
  
  # fix lat lons
  itrk$lat = itrk$lat
  itrk$lon = itrk$long
  
  # get altitude
  alt_i = which(grepl('alt', x = colnames(itrk), ignore.case = T))[1] # select first column containing "alt"
  itrk$altitude = as.numeric(itrk[,alt_i])
  
  # get speed
  spd_i = which(grepl('speed', x = colnames(itrk), ignore.case = T))[1] # select first column containing "spped"
  itrk$speed = as.numeric(itrk[,spd_i])
  
  # remove unused columns
  itrk = itrk[,c('time','lat','lon', 'altitude','speed','date','yday', 'year',  'platform', 'name', 'id')]
  
  # subsample gos
  TRK[[ii]] = subsample_gps(gps = itrk)
  
  # sightings ---------------------------------------------------------------
  
  # take only sightings
  sig = droplevels(tmp[which(as.character(tmp$speccode)!=""),])
  
  # extract data
  sig$lat = sig$lat
  sig$lon = sig$long
  sig$number = as.numeric(as.character(sig$number))
  sig$calves = as.numeric(as.character(sig$numcalf))
  
  # get score
  sig$score[which(sig$number>0)] = 'sighted'
  
  # find indecies of matching
  mind = match(table = spp_key$code, x = sig$speccode)
  
  # replace codes with species names
  sig$species = spp_key$species[mind]
  
  # drop unknown codes
  sig = sig[which(!is.na(sig$species)),]
  
  # keep important columns
  sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','calves','year','platform','name','id')]
  
  # add to the list
  SIG[[ii]] = sig
  
}

# process raw gps ---------------------------------------------------------

glist = grep(pattern = '_GPS.csv$', x = flist)
TRK2 = vector('list', length = length(glist))
for(ii in glist){
  
  # read in data
  tmp = read.csv(flist[ii], as.is = TRUE)
  
  # add required columns
  tmp$time = as.POSIXct(paste0(substr(basename(flist[ii]),1,8), ' ', trimws(substr(tmp$Time, 1,9))), format = '%Y%m%d %H:%M:%S ', tz = 'America/New_York')    ### LN: 11/15 add substr() to tmp$Time to remove weird trailing text
  tmp$time = with_tz(tmp$time, tzone = 'UTC')
  tmp$date = as.Date(tmp$time)
  tmp$yday = yday(tmp$time)
  tmp$year = year(tmp$time)
  tmp$lat = as.numeric(tmp$Lat)
  tmp$lon = as.numeric(tmp$Long)
  tmp$speed = as.numeric(tmp$Speed)
  tmp$altitude = as.numeric(tmp$Alt)
  tmp$platform = 'plane'
  tmp$name = 'neaq'
  tmp$id = paste(tmp$date, tmp$platform, tmp$name, sep = '_')
  
  # remove unused columns
  itrk = tmp[,c('time','lat','lon', 'altitude','speed','date','yday', 'year',  'platform', 'name', 'id')]
  
  # simplify
  itrk = subsample_gps(gps = itrk, tol = 0.0001)
  
  # store
  TRK2[[ii]] = itrk
}

# prep track output -------------------------------------------------------

# combine all tracks
tracks = bind_rows(TRK,TRK2)

# config data types
tracks = config_tracks(tracks)

# remove bad points
tracks = subset(tracks, lon < -50)

# save
saveRDS(tracks, trk_ofile)

# prep sightings output ---------------------------------------------------

# combine all sightings
sightings = bind_rows(SIG)

# config data types
sightings = config_observations(sightings)

# save
saveRDS(sightings, obs_ofile)
