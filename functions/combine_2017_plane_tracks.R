# combine all 2017 flight data for angelia

# libraries
library(plyr)

# functions
source('functions/plot_track.R')

# process all data - MAKE SURE THESE ARE NOT SUBSETTED
source('functions/proc_noaa_twin_otter.R')
source('functions/proc_dfo_twin_otter.R')
source('functions/proc_tc_dash8.R')

# read in all data
noaa = readRDS('data/interim/noaa_twin_otter_tracks.rds')
dfo = readRDS('data/interim/dfo_twin_otter_tracks.rds')
tc = readRDS('data/interim/tc_dash8_tracks.rds')

# save individually -------------------------------------------------------

# define function
plot_save_track = function(trk, fname){
  
  # plot
  png(paste0(fname,'.png'), width = 5, height = 5, units = 'in', res = 250)
  plot_track(trk, span = 2250)
  dev.off()
  
  # save
  write.csv(trk, paste0(fname,'.csv'), row.names = F)
}

# noaa
plot_save_track(noaa, '2017_aerial_tracks-noaa_twin_otter')
# dfo
plot_save_track(dfo, '2017_aerial_tracks-dfo_twin_otter')
# tc
plot_save_track(tc, '2017_aerial_tracks-tc_dash8')

# combine all data --------------------------------------------------------

# combine all data
lst = list(noaa,dfo,tc)

# merge files
tracks = join_all(lst, type = 'full')

# plot
png('2017_aerial_tracks-all.png', width = 5, height = 5, units = 'in', res = 250)
plot_track(tracks, span = 2250)
dev.off()

# write csv
write.csv(tracks, '2017_aerial_tracks-all.csv', row.names = F)
