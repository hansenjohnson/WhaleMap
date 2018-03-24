# process sonobuoy drop times and locations

# user input --------------------------------------------------------------

data_dir = 'data/raw/sonobuoys/'

output_dir = 'data/processed/'

# process -----------------------------------------------------------------

library(readxl, quietly = T, warn.conflicts = F)
library(lubridate, quietly = T, warn.conflicts = F)

# read in data
# dat = read_excel(data_dir)
dat = read.csv(paste0(data_dir, '/NERW_2017_Sonobuoy_Log.Canada.csv'))

# remove top 2 lines (dead sonos)
dat = dat[-c(1:2),]

# fix date
date = as.Date(dat$Date, format = '%d-%b-%y')

# fix time
time = dat$Time.Deployed..ET.

# extract positions
lat = dat$Lat..Deg.Min.
lon = dat$Long..Deg.Min.

# sonobuoy serial number
sn = factor(dat$Sonobuoy.Lot)

# station id
stn_id = dat$Station

# combine into data frame
all = cbind.data.frame(lat,lon,date,time,sn,stn_id)

# start position for each deployment --------------------------------------

sonos = unique(all$sn)

# extract sinlge position for each buoy
TMP = list()
for(i in seq_along(sonos)){
  TMP[[i]] = all[which(sn == sonos[i])[2],]
}

done = do.call(rbind, TMP)

# clean data
done = done[complete.cases(done),]
done = droplevels(done)

# add proper info for subsetting
done$year = year(done$date)
done$yday = yday(done$date)

# save
saveRDS(done, file = paste0(output_dir, '/sonobuoys.rds'))




