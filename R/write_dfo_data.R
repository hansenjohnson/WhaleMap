## write_output_data ##

# user input --------------------------------------------------------------

outdir = 'shared/dfo/data/'
yr = as.numeric(substr(Sys.Date(),start = 1, stop = 4))

# setup -------------------------------------------------------------------

source('R/functions.R')

# make output dir
if(!dir.exists(outdir)){dir.create(outdir)}

# proc observations -------------------------------------------------------

# read in observation data
obs = readRDS('data/processed/observations.rds')

# subset to year
obs = filter(obs, year == yr & !is.na(lat) & !is.na(lon))
obs = subset_canadian(obs)

# subset right whale sightings
rw_sig = filter(obs, species == 'right' & score == 'definite visual')

# sort by date
rw_sig = rw_sig[order(rw_sig$date, decreasing = T),]

# write to csv
write.csv(x = obs, file = paste0(outdir, 'observations.csv'), row.names = F)
write.csv(x = rw_sig, file = paste0(outdir, 'narw_sightings.csv'), row.names = F)

# proc tracks -------------------------------------------------------------

# read in track data
trk = readRDS('data/processed/tracks.rds')

# subset
trk = filter(trk, year == yr & !is.na(lat) & !is.na(lon))
trk = subset_canadian(trk)

# write to csv
write.csv(trk, file = paste0(outdir, 'tracks.csv'), row.names = F)
