## proc_sas_drive ##
# process opportunistic sightings from the NEFSC RWSAS spreadsheet

# input -------------------------------------------------------------------

ifile = 'data/raw/sas/RWSAS_opportunistic_uploads.xlsx'
ofile = 'data/interim/sas_drive_obs.rds'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(readxl))
source('R/functions.R')

# process -----------------------------------------------------------------

# read in data
d = read_excel(ifile, sheet = 1)

# read in org lookup table
orgs = read_excel(ifile, sheet = 3)

# skip example line 
d = d[-1,]

# determine which coords are in DDM and correct
latmin_i = which(!is.na(d$latmin))
lonmin_i = which(!is.na(d$lonmin))
d$lat[latmin_i] = d$lat[latmin_i] + d$latmin[latmin_i]/60
d$lon[lonmin_i] = d$lon[lonmin_i] - d$lonmin[lonmin_i]/60 # hard coded for N hemisphere

# extract important info
obs <- d %>%
  transmute(time = sightdate, 
            lat = lat, 
            lon = lon, 
            date = as.Date(time), 
            yday = yday(date), 
            species = 'right', 
            score = species_cert, 
            number = groupsize, 
            calves = momcalf, 
            year = year(date), 
            category, 
            name = Observer_Org, 
            source = 'RWSAS')

# fix score
obs$score[obs$score == 'Definite'] = 'definite visual'
obs$score[obs$score == 'Probable'] = 'possible visual'
obs$score[obs$score == 'Unknown'] = 'possible visual'

# fix platform
obs$platform = 'opportunistic'
obs$platform[obs$category == 'Dedicated Eg Aerial'] = 'plane'
obs$platform[obs$category == 'Dedicated Eg Shipboard'] = 'vessel'
obs$category = NULL

# remove non-right whales
obs = obs[obs$score != 'Not Egs',]

# fix name
obs$name = orgs$ORG[match(obs$name, table = orgs$ORGCODE)]

# add id
obs$id = paste0(obs$date,'_',obs$platform,'_', obs$name)

# configure observations
OBS = config_observations(obs)

# save
saveRDS(OBS, file = ofile)
