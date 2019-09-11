## proc_2019_dfo_cp_tracks ##
# Process gps data from DFO C&P survey plane

# user input --------------------------------------------------------------

# data directory
data_dir = 'data/raw/2019_whalemapdata/DFO_CP_NARWFlights/'

# output file name
ofile = '2019_dfo_cp_tracks.rds'

# output directory
output_dir = 'data/interim/'

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tools))

# functions
source('R/functions.R')

# plot tracks?
plot_tracks = !on_server()

# list files to process
flist_gpx = list.files(data_dir, pattern = '.gpx', full.names = T, recursive = T, ignore.case = T)
flist_kml = list.files(data_dir, pattern = '.kml', full.names = T, recursive = T, ignore.case = T)
flist = c(flist_gpx,flist_kml)

# list to hold loop output
TRK = vector('list', length = length(flist))

# read and format data ----------------------------------------------------

if(length(flist!=0)){
  
  # read files
  for(i in seq_along(flist)){
    
    if(file.size(flist[i])<51200){
      next
    }
    
    if(length(grep(pattern = '.gpx$', x = flist[i]))==1){
      
      # read in file
      tmp = readOGR(dsn = flist[i], layer="track_points", verbose = F)
      
      # convert to data frame
      tmp = as.data.frame(tmp)
      
      # dummy variable for speed
      tmp$speed = NA
      
      # select and rename important columns
      tmp = data.frame(tmp$time, tmp$coords.x1, tmp$coords.x2, tmp$speed, tmp$ele)
      colnames(tmp) = c('time', 'lon', 'lat', 'speed', 'altitude')
      
      # add timestamp
      tmp$time = as.POSIXct(tmp$time, format = '%Y/%m/%d %H:%M:%OS', tz = 'UTC')
      
    } else {
      
      # read in kml file
      kml_text = suppressWarnings(readLines(flist[i]))
      
      # find coordinates and timestamps
      icoords = grep("*([^<]+?) *<\\/gx:coord>",kml_text)  
      itimes = grep("*([^<]+?) *<\\/when>"  ,kml_text)  
      
      # extract coordinates
      crd = gsub(pattern = "</gx:coord>",replacement = "", x = kml_text[icoords])
      crd = gsub(pattern = "<gx:coord>",replacement = "", x = crd)
      crd = trimws(crd, which = 'both')
      crd = strsplit(crd," ")
      tmp = as.data.frame(do.call(rbind,crd))
      colnames(tmp) = c('lon', 'lat', 'altitude')
      tmp$lon = as.numeric(as.character(tmp$lon))
      tmp$lat = as.numeric(as.character(tmp$lat))
      tmp$altitude = as.numeric(as.character(tmp$altitude))
      
      # extract times
      tim = gsub(pattern = "</when>",replacement = "", x = kml_text[itimes])
      tim = gsub(pattern = "<when>",replacement = "", x = tim)
      tim = trimws(tim, which = 'both')
      tmp$time = as.POSIXct(tim, format = '%Y-%m-%dT%H:%M:%S', tz = 'UTC')
    
      # dummy variable for speed
      tmp$speed = NA
    
      # quick plot
      # plot_track(tmp)
    }
    
    # subsample (use default subsample rate)
    tracks = subsample_gps(gps = tmp)
    
    # add metadata
    if(is.na(tracks$time[1])){
      tracks$date = as.Date(strtrim(basename(flist[i]), width = 8), format = '%Y%m%d')
    } else {
      tracks$date = as.Date(tracks$time)  
    }
    tracks$yday = yday(tracks$date)
    tracks$year = year(tracks$date)
    tracks$platform = 'plane'
    tracks$name = 'dfo_cp'
    tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')
    
    # # plot track
    # if(plot_tracks){
    #   plot_save_track(tracks, flist[i])
    # }
    
    # add to list
    TRK[[i]] = tracks
    
    # catch null error
    if(is.null(TRK[[i]])){stop('Track in ', flist[i], ' not processed correctly!')}
    
  }
  
  # combine all flights
  TRACKS = bind_rows(TRK)
  
} else {
  
  # assign empty data frame
  TRACKS = data.frame()
}

# combine and save --------------------------------------------------------

# config flight data
tracks = config_tracks(TRACKS)

# save
saveRDS(tracks, paste0(output_dir, ofile))
