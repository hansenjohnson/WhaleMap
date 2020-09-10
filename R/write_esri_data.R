## write_esri_data ##

# user input --------------------------------------------------------------

outdir = 'shared/esri/data/'

# setup -------------------------------------------------------------------

source('R/functions.R')

# make output dir
if(!dir.exists(outdir)){dir.create(outdir, recursive = TRUE)}

# determine current year
yr = year(Sys.Date())

# proc observations -------------------------------------------------------

# read in observation data
obs = readRDS('data/processed/observations.rds')

# subset to year
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
