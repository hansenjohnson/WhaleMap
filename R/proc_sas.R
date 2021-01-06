## proc_sas ##
# read data from NOAA SAS

# input -------------------------------------------------------------------

# input files
obs_file = 'data/processed/observations.rds'
from_sas_file = 'data/raw/sas/xmlgenSAS_H.pl'
sas_key_file = 'data/raw/sas/RWSASorganizations.xlsx'
keep_sas_file = 'data/interim/sas_sightings.rds'
to_sas_dir = 'shared/sas/'

# list WhaleMap platform names to not send from WhaleMap to RWSAS
no_send_list = c('noaa_twin_otter')

# # list organizations to not plot on WhaleMap from SAS
# no_plot_list = c("NOAA|Southeast Fisheries Science Center (SEFSC) | Miami")

# define latitude below which dedicated surveys are excluded from WhaleMap
sas_lat = 36.5

# switch to include sas on WhaleMap
plot_sas = TRUE

# switch to make WhaleMap data available for sas
send_sas = TRUE

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(xml2))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(lubridate))
source('R/functions.R')

# define start and end times of subset
t1 = Sys.Date()
t0 = t1 - 365

# make output dir
if(!dir.exists(to_sas_dir)){dir.create(to_sas_dir, recursive = TRUE)}

# process raw sas ---------------------------------------------------------

if(file.exists(from_sas_file)){
  
  # find all sightings nodes
  tmp = xml_find_all(read_xml(from_sas_file), ".//sight")
  
  # extract data
  sas = data.frame(
    id = as.numeric(xml_attr(tmp, "id")),
    time = as.POSIXct(xml_attr(tmp, "sightdate"), tz = 'UTC'),
    lat = as.numeric(xml_attr(tmp, "lat")),
    lon = as.numeric(xml_attr(tmp, "lon")),
    number = as.numeric(xml_attr(tmp, "groupsize")),
    calves = as.character(xml_attr(tmp, "momcalf")),
    platform = as.character(xml_attr(tmp, "category")),
    score = as.character(xml_attr(tmp, "description"))
  )
  
  # convert column types
  sas$platform = as.character(sas$platform)
  sas$score = as.character(sas$score)
  sas$calves = ifelse(sas$calves=='Yes', yes = 1, no = 0)
  
  # read in org key
  org_key = read_excel(sas_key_file)
  
  # read in org codes
  org_codes = as.numeric(xml_attr(tmp, "obs_org"))
  
  # define sas organizations
  sas_org = org_key$Observer_org[match(table = org_key$Code, x = org_codes)]
  
  # list opportunistic platforms
  opp_list = c('Opportunistic', 
               'Commercial vessel', 
               'Fishing Vessel',
               'US Coast Guard', 
               'Volunteer Sighting Network',
               'Whale watch',
               'Unknown')
  
  # convert platform levels
  sas$platform[sas$platform %in% opp_list] = 'opportunistic'
  sas$platform[sas$platform == 'Dedicated Eg Aerial'] = 'plane'
  sas$platform[sas$platform == 'Dedicated Eg Shipboard'] = 'vessel'
  
  # convert score levels
  sas$score[sas$score == 'Definite'] = 'sighted'
  sas$score[sas$score %in% c('Probable', 'Unknown')] = 'possibly sighted'
  
  # add columns
  sas = sas %>%
    mutate(
      date = as.Date(time),
      yday = yday(time),
      year = year(time),
      species = 'right',
      name = paste0('SAS-', id),
      id = paste0(date, '_', platform, '_', name)
    )
  
  # configure
  sas = config_observations(sas)
  
  # clean lat/lons
  sas = clean_latlon(sas)
  
  # compare sas whalemap ----------------------------------------------------
  
  # read in whalemap observations
  obs = readRDS(obs_file) 
  
  # add identifier
  obs$whalemap_id = seq(1, nrow(obs),1)
  
  # filter
  obs = obs %>%
    filter(date >= t0 & date <= t1 & species == 'right' & 
             score %in% c('definite visual') & !is.na(lat) & !is.na(lon) &
             !grepl('SAS-', name))
  
  # define columns to compare
  m_obs = paste0(obs$date, round(obs$lat,0), round(obs$lon,0))
  m_sas = paste0(sas$date, round(sas$lat,0), round(sas$lon,0))
  
  # determine records to add to WhaleMap
  to_keep = sas %>%
    filter(!(m_sas %in% m_obs) & !(lat <= sas_lat & platform != 'opportunistic'))
  
  # determine records to send to SAS
  to_send = obs %>%
    filter(!(m_obs %in% m_sas) & !(name %in% no_send_list))  
  
  # reorder data by date
  to_send = to_send[order(to_send$date, decreasing = TRUE),]
  
  # fill in dummy time data if needed
  bad_times = is.na(to_send$time)
  to_send$time[bad_times] = as.POSIXct(paste0(to_send$date[bad_times], ' 12:00:00 UTC'))
  
  # add another level to flag duplicates on a different day (?)
  
  # write outputs -----------------------------------------------------------
  
  if(plot_sas){
    # whalemap
    saveRDS(object = to_keep, file = keep_sas_file)
  }
  
  if(send_sas){
    # sas
    write.csv(x = to_send, file = paste0(to_sas_dir, 'whalemap-data.csv'), row.names = FALSE)
  }
}

# test --------------------------------------------------------------------

# # new additions to WhaleMap
# library(leaflet)
# leaflet() %>%
#   addProviderTiles(providers$Esri.OceanBasemap) %>%
# 
#   # existing whalemap
#   addCircleMarkers(data = obs, lat = ~lat, lng = ~lon, label = ~id, radius = 4,
#                    stroke = TRUE, weight = 2, color = 'black', fillColor = 'grey', fillOpacity = .8) %>%
# 
#   # from SAS
#   addMarkers(data = to_keep, lat = ~lat, lng = ~lon, label = ~id)
# 
# # New additions to SAS map
# leaflet() %>%
#   addProviderTiles(providers$Esri.OceanBasemap) %>%
# 
#   # existing SAS
#   addCircleMarkers(data = sas, lat = ~lat, lng = ~lon, label = ~id, radius = 4,
#                    stroke = TRUE, weight = 2, color = 'black', fillColor = 'grey', fillOpacity = .8) %>%
# 
#   # from whalemap
#   addMarkers(data = to_send, lat = ~lat, lng = ~lon, label = ~id)
# 
