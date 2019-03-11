## plot_database ##
# Plot simple maps of all tracks and observations in the processed database

# user input --------------------------------------------------------------

# output directory for all figures
odir = 'figures/all/'

# setup -------------------------------------------------------------------

library(oce)
library(ocedata)
data("coastlineWorldFine")

# create out dir
if(!dir.exists(odir)){dir.create(odir)}

# process -----------------------------------------------------------------

# read in data
tracks = readRDS('data/processed/tracks.rds')
obs = readRDS('data/processed/observations.rds')

# subset right whales
obs = obs[obs$species == 'right',]

# separate tracks by deployment
ltracks = split(tracks, f = tracks$id)

# loop through each deployment and plot
for(i in seq_along(ltracks)){
  
  # select tracks
  tr = ltracks[[i]]
  
  # determine track id
  trid = unique(tr$id)
  
  # remove na's in track
  tr = tr[!is.na(tr$lat),]
  tr = tr[!is.na(tr$lon),]
  
  # skip if empty
  if(nrow(tr)==0){
    message('Skipping track: ', trid)
    next
  }
  
  # select obs (by id)
  ob = obs[obs$id == trid,]
  
  # plotting dimensions
  span = 4 * 111 * diff(range(tr$lat, na.rm = T))
  
  # start plot
  png(paste0(odir, trid, '.png'), width = 5, height = 5, units = 'in', res = 100)
  
  # plot basemap
  plot(coastlineWorldFine,
       clon = mean(tr$lon, na.rm = T),
       clat = mean(tr$lat, na.rm = T),
       span = span
  )
  
  # add lines
  lines(tr$lon, tr$lat, col = 'blue')
  points(tr$lon, tr$lat, col = 'black', pch = 4, cex = .3)
  
  # add sightings
  points(ob$lon, ob$lat, pch = 21, bg = 'red')
  
  # add id
  mtext(paste0('ID: ', unique(tr$id)), side = 3, adj = 0)
  
  # add legend
  legend('topright', cex = .7,
         lty = c(NA, 1), 
         pch = c(21, 4), 
         col = c('black', 'blue'), 
         pt.bg = c('red', NA), 
         c('Right whale observation', 'Track')
  )
  
  # write plot
  dev.off()
}


