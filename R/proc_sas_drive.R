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
orgs = read_excel(ifile, sheet = "Organizations")

# skip example line 
d = d[-1,]

# remove lines without time or position
d = d %>% filter(!is.na(sightdate) & !is.na(lat) & !is.na(lon))

# determine which coords are in DDM and correct
latmin_i = which(!is.na(d$latmin))
lonmin_i = which(!is.na(d$lonmin))
d$lat[latmin_i] = d$lat[latmin_i] + d$latmin[latmin_i]/60
d$lon[lonmin_i] = d$lon[lonmin_i] - d$lonmin[lonmin_i]/60 # hard coded for N hemisphere

# restrict to only records that should be displayed
d = d[d$display == 'yes',]

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
            source = 'RWSAS') %>%
  filter(!is.na(lat) & !is.na(lon) & !is.na(time))

# convert to UTC time
tz(obs$time) = 'America/New_York'
obs$time = with_tz(obs$time, tzone = 'UTC')

# force negative longitude
obs$lon = -abs(obs$lon)

# fix platform
obs$platform = 'opportunistic'
obs$platform[obs$category == 'Dedicated Eg Aerial'] = 'plane'
obs$platform[obs$category == 'Dedicated Eg Shipboard'] = 'vessel'
obs$platform[obs$category == 'Opportunistic - Small Vessel Survey'] = 'vessel'

# fix score
obs$score[obs$score == 'Definite'] = 'definite visual'
obs$score[obs$score == 'Probable'] = 'possible visual'
obs$score[obs$score == 'Unknown'] = 'possible visual'
obs$score[obs$score == 'definite visual' & obs$category == 'Acoustic Detection'] = 'definite acoustic'
obs$score[obs$score == 'possible visual' & obs$category == 'Acoustic Detection'] = 'possible acoustic'

# remove category
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
