# combine all 2017 flight data for angelia

# process all data
source('functions/noaa_twin_otter.R')
source('functions/dfo_twin_otter.R')
source('functions/tc_dash8.R')

# read in all data
noaa = readRDS('data/interim/noaa_twin_otter.rds')
dfo = readRDS('data/interim/dfo_twin_otter.rds')
tc = readRDS('data/interim/tc_dash8.rds')

# combine all data
lst = list(noaa,dfo,tc)
tracks = Reduce(function(x, y) merge(x, y, all=TRUE), lst)

# write csv
write.csv(tracks, '2017_aerial_tracks-spd-alt.csv', row.names = F)
