# process sonobuoy drop times and locations

# user input --------------------------------------------------------------

ifile = 'data/raw/noaa_sonobuoys/NERW_Sonobuoy_Log_MASTER.xlsx.csv'

output_dir = 'data/processed/'

# process -----------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(lubridate))

# read in data
tmp = read.csv(ifile)

# remove first line (example input)
tmp = tmp[-1,]

# fix date and time
tmp$date = as.Date(tmp$Date, format = '%d-%b-%y')
tmp$time = as.POSIXct(paste0(tmp$date, ' ', tmp$Time..ET.), format = '%Y-%m-%d %H:%M:%S', tz = 'US/Eastern')
tmp$year = year(tmp$date)
tmp$yday = yday(tmp$date)

# extract positions
tmp$lat = suppressWarnings(as.numeric(as.character(tmp$Lat..Deg.Min.)))
tmp$lon = suppressWarnings(as.numeric(as.character(tmp$Long..Deg.Min.)))

# sonobuoy serial number
tmp$sn = as.factor(tmp$Sonobuoy.Lot)

# station id
tmp$stn_id = as.factor(tmp$Station)

# comments
tmp$comments = as.character(tmp$Comments)

# select only actual positions of successful deployments
tmp = tmp[grepl(x = tmp$comments, pattern = 'ap', ignore.case = TRUE) & tmp$Deploy.Success. == 'yes',]

# take unique position from each station
tmp = tmp[which(!duplicated(tmp$stn_id)),]

# select only helpful columns
tmp = tmp[,c('time','lat','lon','date','year','yday','sn','stn_id')]

# save
saveRDS(tmp, file = paste0(output_dir, '/sonobuoys.rds'))
