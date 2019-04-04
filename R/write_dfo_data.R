## write_output_data ##

# user input --------------------------------------------------------------

outdir = 'shared/dfo/data/'
yr = 2019

# setup -------------------------------------------------------------------

source('R/functions.R')

# make output dir
if(!dir.exists(outdir)){dir.create(outdir)}

# proc observations -------------------------------------------------------

# read in observation data
obs = readRDS('data/processed/observations.rds')

# subset
obs = filter(obs, year == yr & !is.na(lat) & !is.na(lon))
obs = subset_canadian(obs)

# write to csv
write.csv(x = obs, file = paste0(outdir, 'observations.csv'), row.names = F)

# proc tracks -------------------------------------------------------------

# read in track data
trk = readRDS('data/processed/tracks.rds')

# subset
trk = filter(trk, year == yr & !is.na(lat) & !is.na(lon))
trk = subset_canadian(trk)

# write to csv
write.csv(trk, file = paste0(outdir, 'tracks.csv'), row.names = F)
