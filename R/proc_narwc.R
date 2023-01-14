## proc_narwc ##
# process historical NARWC observations

# input -------------------------------------------------------------------

# input file
ifile <- 'data/raw/narwc/NARWC22N.CSV'

# header file
hfile <- 'data/raw/narwc/NARWC22N_sample.CSV'

# output file
ofile <- 'data/interim/narwc_obs.rds'

# earliest year
yr <- 2010

# setup -------------------------------------------------------------------

source('R/functions.R')

# process -----------------------------------------------------------------

# read in header info
hdr <- read_csv(hfile) %>% colnames()

# read in data and remove effort/sightings from previous years
all <- read_csv(ifile, col_names = hdr) %>%
  filter(YEAR >= yr & SPECCODE != "xxxx")

# make date column
all$date <- as.Date(paste0(all$YEAR, '-', all$MONTH, '-', all$DAY), format = '%Y-%m-%d')

# make time column
all$time <- as.POSIXct(paste0(all$YEAR, '-', all$MONTH, '-', all$DAY, ' ', all$TIME),
                      format = '%Y-%m-%d %H%M%S', tz = 'UTC', usetz = T)

# calculate yday
all$yday <- yday(all$date)

# calculate year
all$year <- all$YEAR

# lat lon
all$lat <- as.numeric(all$LAT_DD)
all$lon <- as.numeric(all$LONG_DD)

# species codes
all$species = NA
all$species[all$SPECCODE == 'RIWH'] <- 'right'
all$species[all$SPECCODE == 'FIWH'] <- 'fin'
all$species[all$SPECCODE == 'HUWH'] <- 'humpback'
all$species[all$SPECCODE == 'BLWH'] <- 'blue'
all$species[all$SPECCODE == 'SEWH'] <- 'sei'

# remove unknown species
all <- all[!is.na(all$species),]

# remove dead whales
all <- all[!(as.numeric(all$BEHAV1) %in% c(0, 1)),]

# number
all$number <- as.numeric(all$NUMBER)
all$number[all$number == 99999] = NA

# calves
all$calves <- as.numeric(all$NUMCALF)
all$calves[all$calves == 999] = NA

# score
all$score <- NA
all$score[all$IDREL %in% c(1,2,9)] <- 'possibly sighted'
all$score[all$IDREL == 3] <- 'sighted'

# extract platform info
all$platform = NA
fid = substr(all$FILEID, 0, 1)
all$platform[fid == 'o'] <- 'opportunistic'
all$platform[fid == 'p'] <- 'vessel'
all$platform[fid %in% c('a', 'b', 'c', 'f')] <- 'plane'
all$platform[all$IDSOURCE == "TAG"] <- 'tag'

# define name
all$name = paste0('NARWC-', all$DDSOURCE)

# id
all$id <- all$FILEID

# remove missing values
all <- all %>% filter(!is.na(date) & !is.na(species) & !is.na(lat) & !is.na(lon) & !is.na(platform))

# add source
all$source <- 'NARWC'

# configure observations
rwc <- config_observations(all)

# save
saveRDS(rwc, ofile)
