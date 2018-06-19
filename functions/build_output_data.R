# build output data files

# user input --------------------------------------------------------------

outdir = 'output/'

# setup -------------------------------------------------------------------

# make output dir
if(!dir.exists(outdir)){dir.create(outdir)}

# proc observations -------------------------------------------------------

# read in observation data
obs = readRDS('data/processed/observations.rds')

# subset
obs = obs[obs$year == 2018,]

# write to csv
write.csv(x = obs, file = paste0(outdir, 'observations.csv'), row.names = F)

# proc tracks -------------------------------------------------------------

# read in track data
trk = readRDS('data/processed/tracks.rds')

# subset
trk = trk[trk$year == 2018,]

# write to csv
write.csv(trk, file = paste0(outdir, 'tracks.csv'), row.names = F)


