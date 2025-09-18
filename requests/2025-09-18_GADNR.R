## 2025-09-18_GADNR ##
# request from Georgia DNR for sightings and effort data from Jan 2025 in the SEUS to use for internal tool development

# input -------------------------------------------------------------------

t0 = as.Date('2025-01-01')
t1 = as.Date('2025-01-31')
max_lat = 38
max_lon = -72
request_dir = 'requests/2025-09-18_GADNR/'

# setup -------------------------------------------------------------------

library(rnaturalearth)
source("global.R")
source("R/functions.R")

# observations ------------------------------------------------------------

# read in data
obs = readRDS('data/processed/observations.rds') %>%
  filter(date >= t0 & date <= t1 & lat <= max_lat & lon <= max_lon) %>%
  filter(!is.na(lat) & !is.na(lon) & species == 'right')

# effort ------------------------------------------------------------------

# read in data
eff = readRDS('data/processed/effort.rds') %>%
  filter(date >= t0 & date <= t1 & lat <= max_lat & lon <= max_lon)

# save --------------------------------------------------------------------

# write csv
write_csv(x = obs, file = paste0(request_dir, 'observations.csv'))
write_csv(x = eff, file = paste0(request_dir, 'effort.csv'))

# check -------------------------------------------------------------------

# plot setup
xlims = range(c(obs$lon,eff$lon), na.rm = TRUE)
ylims = range(c(obs$lat,eff$lat), na.rm = TRUE)
bg = ne_countries(scale = "large", continent = 'North America', returnclass = "sf")

# plot
p = ggplot()+
  geom_sf(data = bg)+
  geom_path(data = eff, aes(x = lon, y = lat, color = platform, group = id))+
  geom_point(data = obs, aes(x = lon, y = lat, fill = score), shape = 21, alpha = 0.7)+
  scale_fill_manual(values = score_cols) +
  coord_sf(xlim = xlims, ylim = ylims)+
  labs(x = NULL, y = NULL, fill = 'Score', color = "Platform",
       title = 'WhaleMap data', subtitle = paste0('Extracted on ', Sys.Date())) +
  theme_bw()+
  theme(panel.grid = element_blank())

# save
ggsave(
  filename = paste0(request_dir, 'WhaleMap_summary.jpg'),
  plot = p,
  width = 6,
  height = 8,
  units = 'in',
  dpi = 300
)


