## WhaleMap data request ##
# Request for select days by Jenn Verma

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
REQUEST_NAME = '2025-07-22_verma'

## select specific dates
DATES = c('2024-05-29', '2024-06-01', '2024-07-02', '2024-07-03', '2024-07-09', '2024-07-14', '2024-07-15', 
          '2024-07-19', '2024-07-20', '2024-07-21', '2024-07-22', '2024-07-27', '2024-08-11', '2024-08-15', 
          '2024-08-16', '2024-08-24', '2025-02-03')

# species
SPECIES = c("right") # choose from: c("right", "fin", "sei", "humpback", "blue")

# score / observation type
SCORES = c("definite visual") # choose from: c("definite visual", "definite acoustic", "possible visual", "possible acoustic")

# data provider
DATAPROVIDERS = c("noaa_twin_otter", "neaq", "twin_otter_noaa_57") # choose from many, including c("noaa_twin_otter", "ccs", "neaq")

# facet variable (for summary plot)
PLOTVAR = 'name'

# setup -------------------------------------------------------------------

# read in packages / global variables / functions
library(rnaturalearth)
source("global.R")
source("R/functions.R")

# create request directory
request_dir = paste0('requests/', REQUEST_NAME, '/')
if(!dir.exists(request_dir)){dir.create(request_dir, recursive = T)}

# configure variables
DATES = as.Date(DATES)

# observations ------------------------------------------------------------

# filter observations and remove NAs
obs = readRDS('data/processed/observations.rds') %>%
  filter(!is.na(lat) & !is.na(lon) & !is.na(date))

# species
obs = obs %>% filter(species %in% SPECIES)

# score
obs = obs %>% filter(score %in% SCORES)

# dates
obs = obs %>% filter(date %in% DATES)

# providers
obs = obs %>% filter(name %in% DATAPROVIDERS)

# fix providers
obs$name[obs$name == "twin_otter_noaa_57"] = "noaa_twin_otter"

# restrict to necessary columns
obs = obs %>% select("date", "lat", "lon", "species", "score", "number", "calves", "platform", "name", "id", "source")

# save
write.csv(obs, file = paste0(request_dir,'WhaleMap_observations.csv'), row.names = FALSE)

# plot --------------------------------------------------------------------

# plot setup
xlims = range(c(obs$lon), na.rm = TRUE)
ylims = range(c(obs$lat), na.rm = TRUE)
bg = ne_countries(scale = "large", continent = 'North America', returnclass = "sf")
obs$plotname = obs$name

# plot
p = ggplot()+
  geom_point(data = obs, aes(x = lon, y = lat, fill = score), shape = 21, alpha = 0.7)+
  scale_fill_manual(values = score_cols) +
  geom_sf(data = bg)+
  coord_sf(xlim = c(-74, -69), ylim = c(39,42))+
  facet_wrap(~plotname)+
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