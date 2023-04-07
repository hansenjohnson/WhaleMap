## WhaleMap data request ##
# Request from Carl Lemire with NOAA Office of Law Enforcement for right whale 
# data around Morehead City/Beaufort and Chesapeake Bay/Norfolk SMAs over several
# time frames from the previous six months.

# Steps to pull data
# 0: Pull latest data from WhaleMap server
# 1: fill in inputs to filter data. Leave unused filters set to "NA"
# 2: save script in "requests/" using the request name as the file name
# 3: source script 
# 4: check map and summary to confirm request was correct
# 5: send data (typically compress request directory and send via email)
# 6: commit request script to git and push to GitHub

# input -------------------------------------------------------------------

# request name

REQUEST_NAME = '2023-04-07_LEMIRE'

# include effort (TRUE), or only observations (FALSE)

INCLUDE_EFFORT = FALSE # enter TRUE or FALSE

# set lat/lon limits

## define a bounding box (use decimal degrees)

MIN_LAT = 34.00 
MAX_LAT = 38.00
MIN_LON = -78.00
MAX_LON = -74.00

## restrict to US/CAN waters 

US_only = TRUE # enter TRUE or FALSE
CAN_only = FALSE # enter TRUE or FALSE

# time limits

## select months across years
YEARS = NA # choose specific years using: c(2018,2019,2020)
MONTHS = NA # choose specific months using: c("January", "February", "March")

## select inclusive time range
START_DATE = "2022-11-03" # enter as follows: "2018-04-01" (set to NA to not use)
END_DATE = "2023-02-11" # enter as follows: "2018-04-01" (set to NA to not use)

# species

SPECIES = c("right") # choose from: c("right", "fin", "sei", "humpback", "blue")

# score / observation type

SCORES = c("definite visual") # choose from: c("definite visual", "definite acoustic", "possible visual", "possible acoustic")

# platform

PLATFORMS = NA # choose from: c("buoy", "slocum", "plane", "vessel", "rpas")

# data source 

DATASOURCES = c("WhaleMap", "RWSAS") # choose from: c("WhaleMap", "WhaleInsight", "RWSAS", "NARWC")

# data provider

DATAPROVIDERS = NA # choose from many, including c("noaa_twin_otter", "ccs", "neaq")

# facet variable (for summary plot)

PLOTVAR = 'source'

# setup -------------------------------------------------------------------

# read in packages / global variables / functions
library(rnaturalearth)
source("global.R")
source("R/functions.R")

# create request directory
request_dir = paste0('requests/', REQUEST_NAME, '/')
if(!dir.exists(request_dir)){dir.create(request_dir, recursive = T)}

# configure variables
START_DATE = as.Date(START_DATE)
END_DATE = as.Date(END_DATE)

# observations ------------------------------------------------------------

# filter observations and remove NAs
obs = readRDS('data/processed/observations.rds') %>%
  filter(!is.na(lat) & !is.na(lon) & !is.na(date))

# data sources
if(!TRUE %in% is.na(DATASOURCES)){
  obs = obs %>% filter(source %in% DATASOURCES)
}

# species
if(!TRUE %in% is.na(SPECIES)){
  obs = obs %>% filter(species %in% SPECIES)
}

# score
if(!TRUE %in% is.na(SCORES)){
  obs = obs %>% filter(score %in% SCORES)
}

# platforms
if(!TRUE %in% is.na(PLATFORMS)){
  obs = obs %>% filter(score %in% PLATFORMS)
}

# providers
if(!TRUE %in% is.na(DATAPROVIDERS)){
  obs = obs %>% filter(name %in% DATAPROVIDERS)
}

# time: months across years
if(!TRUE %in% is.na(c(MONTHS, YEARS))){
  obs$month = month(obs$date, label = TRUE, abbr = FALSE)
  obs = obs %>% filter(month %in% MONTHS & year %in% YEARS)
}

# time: inclusive time range
if(!TRUE %in% is.na(c(START_DATE, END_DATE))){
  obs = obs %>% filter(date >= START_DATE & date <= END_DATE)
}

# space: bounding box
if(!TRUE %in% is.na(c(MIN_LAT, MAX_LAT, MIN_LON, MAX_LON))){
  obs = obs %>% filter(lat >= MIN_LAT & lat <= MAX_LAT & lon >= MIN_LON & lon <= MAX_LON)
}

# space: us only
if(US_only){
  obs = obs %>% subset_canadian(inside = FALSE)
}

# space: can only
if(CAN_only){
  obs = obs %>% subset_canadian(inside = TRUE)
}

# restrict to necessary columns
obs = obs %>% select("time", "year", "date", "lat", "lon", "species", "score", "number", "calves", "platform", "name", "id", "source")

# save
write.csv(obs, file = paste0(request_dir,'WhaleMap_observations.csv'), row.names = FALSE)

# effort ------------------------------------------------------------------

if(INCLUDE_EFFORT){
  
  # filter observations and remove NAs
  eff = readRDS('data/processed/effort.rds') %>%
    filter(!is.na(lat) & !is.na(lon) & !is.na(date))
  
  # data sources
  if(!TRUE %in% is.na(DATASOURCES)){
    eff = eff %>% filter(source %in% DATASOURCES)
  }
  
  # platforms
  if(!TRUE %in% is.na(PLATFORMS)){
    eff = eff %>% filter(score %in% PLATFORMS)
  }
  
  # providers
  if(!TRUE %in% is.na(DATAPROVIDERS)){
    eff = eff %>% filter(name %in% DATAPROVIDERS)
  }
  
  # time: months across years
  if(!TRUE %in% is.na(c(MONTHS, YEARS))){
    eff$month = month(eff$date, label = TRUE, abbr = FALSE)
    eff = eff %>% filter(month %in% MONTHS & year %in% YEARS)
  }
  
  # time: inclusive time range
  if(!TRUE %in% is.na(c(START_DATE, END_DATE))){
    eff = eff %>% filter(date >= START_DATE & date <= END_DATE)
  }
  
  # space: bounding box
  if(!TRUE %in% is.na(c(MIN_LAT, MAX_LAT, MIN_LON, MAX_LON))){
    eff = eff %>% filter(lat >= MIN_LAT & lat <= MAX_LAT & lon >= MIN_LON & lon <= MAX_LON)
  }
  
  # space: us only
  if(US_only){
    eff = eff %>% subset_canadian(inside = FALSE)
  }
  
  # space: can only
  if(CAN_only){
    eff = eff %>% subset_canadian(inside = TRUE)
  }
  
  # restrict to necessary columns
  eff = eff %>% select("time", "year","date", "lat", "lon", "platform", "name", "id", "source")
  
  # save
  write.csv(eff, file = paste0(request_dir,'WhaleMap_effort.csv'), row.names = FALSE)
  
} else {
  
  eff = config_tracks(data.frame())
  
}

# plot --------------------------------------------------------------------

# plot setup
# spp_shapes = c(21,22,23,24,25)
# spp_shapes = spp_shapes[1:length(SPECIES)]
xlims = range(c(obs$lon,eff$lon), na.rm = TRUE)
ylims = range(c(obs$lat,eff$lat), na.rm = TRUE)
bg = ne_countries(scale = "large", continent = 'North America', returnclass = "sf")

# plot
p = ggplot()+
  geom_sf(data = bg, fill = "cornsilk", color = "cornsilk4", size = 0.2)+
  geom_path(data = eff, aes(x = lon, y = lat, color = platform, group = id), alpha = 0.7)+
  geom_point(data = obs, aes(x = lon, y = lat, fill = score), shape = 21, alpha = 0.7)+
  scale_color_manual(values = platform_cols) +
  scale_fill_manual(values = score_cols) +
  coord_sf(xlim = xlims, ylim = ylims)+
  facet_wrap(as.formula(paste(".~", PLOTVAR)))+
  labs(x = NULL, y = NULL, fill = 'Score', color = "Platform",
       title = 'WhaleMap data', subtitle = paste0('Extracted on ', Sys.Date())) +
  theme_bw()+
  theme(panel.grid = element_blank())

# save
ggsave(
  filename = paste0(request_dir, 'WhaleMap_summary.jpg'),
  plot = p,
  width = 10,
  height = 6,
  units = 'in',
  dpi = 300
)

message("WhaleMap data pull complete!")
message("   Extracted data are in: ", request_dir)
message("   Double check the plot and the following data summary:")
print(summary(obs))
message("Done!")