# read and format cnp test data

ifile = 'test/cnp/MammalTargetReport.xlsx'

# setup -------------------------------------------------------------------

# libraries
library(readxl)
library(measurements)
library(lubridate)

# read in data
df = read_excel(ifile)

# # extract date from metadata
# day = df$X__1[grep('Mission Date:',df$X__1)]
# day = as.Date(as.POSIXct(day, format = 'Mission Date: %Y-%m-%dT%H:%M:%S', tz = 'America/Halifax'))

# select table
df_id = grep('ID',df$X__1)
names = as.character(df[df_id,])
df = as.data.frame(df[(df_id+1):(nrow(df)-1),])
colnames(df) = names

# extract data ------------------------------------------------------------

# extract position
pos = df$`Target Position`
pos = strsplit(pos, ' ')

# lat
lat = sapply(pos, function(x) x[[1]])
lat = gsub(pattern = '°', replacement = ' ', lat)
lat = gsub(pattern = '\'N', replacement = '', lat)
lat = as.numeric(measurements::conv_unit(lat, from = 'deg_dec_min', to = 'dec_deg'))

# lon
lon = sapply(pos, function(x) x[[2]])
lon = gsub(pattern = '°', replacement = ' ', lon)
lon = gsub(pattern = '\'W', replacement = '', lon)
lon = as.numeric(measurements::conv_unit(lon, from = 'deg_dec_min', to = 'dec_deg'))*-1

# extract time
time = as.POSIXct(df$Create, format = '%m/%d %H:%M:%S', tz = 'America/Halifax')

# extract number
number = as.numeric(df$No.)

# extract date
date = as.Date(time)

# extract species
species = as.factor(df$Type)

# combine into table
obs = data.frame(date, time, lat, lon, species, number)

# add other columns
obs$platform = as.factor('opportunistic')
obs$name = as.factor('other')
obs$score = as.factor('possibly sighted')
obs$yday = yday(obs$time)
obs$id = paste(obs$date,obs$platform, obs$name, sep = '_')

# save output
