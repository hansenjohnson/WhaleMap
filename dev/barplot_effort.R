# make bar plot to indicate effort


# setup -------------------------------------------------------------------

library(ggplot2)
library(plotly)

# definitions -------------------------------------------------------------

# time period to show (days)
start_date = as.Date('2017-06-01')
end_date = as.Date('2017-12-30')

# output path
fout = '../server_index/whale_map.html'

# define score color palette
obs_levs = c('detected', 'possibly detected', 'possibly sighted','sighted')
obs_pal = c('red', 'yellow', 'grey','darkslategray')
pal = colorFactor(levels = obs_levs, palette = obs_pal)

# define visual and acoustic platforms
visual_platforms = c('plane', 'vessel')
acoustic_platforms = c('slocum', 'buoy', 'wave')

# make dcs icons
dcsIcons = iconList(
  slocum = makeIcon("icons/slocum.png", iconWidth = 40, iconHeight = 40),
  wave = makeIcon("icons/wave.png", iconWidth = 35, iconHeight = 30),
  buoy = makeIcon("icons/buoy.png", iconWidth = 50, iconHeight = 40)
)

# define function to determine trackline color
getColor <- function(tracks) {
  if(tracks$platform[1] == 'slocum') {
    "blue"
  } else if(tracks$platform[1] == 'plane') {
    "#8B6914"
  } else if(tracks$platform[1] == 'vessel'){
    "black"
  } else if(tracks$platform[1] == 'wave'){
    "purple"
  } else {
    "darkgrey"
  }
}

# read in data -------------------------------------------------------

# tracklines
TRACKS = readRDS('data/processed/tracks.rds')

# sightings / detections
OBS = readRDS('data/processed/observations.rds')

# subset data -------------------------------------------------------------

# tracklines
tracks = TRACKS[TRACKS$date >= start_date & TRACKS$date <= end_date,]; rm(TRACKS)
tracks = tracks[tracks$name!='cp_king_air',] # do not plot C&P data

# observations
Obs = OBS[OBS$date >= start_date & OBS$date <= end_date,]; rm(OBS)

# select platform
tracks = tracks[tracks$platform %in% c('slocum','plane','vessel'),] # do not plot C&P data
Obs = Obs[Obs$platform %in% c('slocum','plane','vessel'),] # do not plot C&P data

# select species
spp = Obs[Obs$species == 'right',]

# only possible detections
pos = droplevels(spp[spp$score == 'possibly detected',]) # do not plot possible sightings

# only definite
det = droplevels(spp[!spp$score %in% c('possibly detected', 'possibly sighted'),])

# data for barplot --------------------------------------------------------

# define plot data
obs = droplevels(rbind(pos, det))

# make categories for facet plotting
obs$cat = ''
obs$cat[obs$score == 'sighted' | obs$score == 'possibly sighted'] = 'Sighting events per day'
obs$cat[obs$score == 'detected' | obs$score == 'possibly detected'] = 'Detection events per day'

# determine number of factor levels to color
ncol = length(obs_levs)

# manually define colors based on score
fillcols = scale_fill_manual(values = c('sighted' = 'black', 
                                        'possibly sighted' = 'grey',
                                        'detected' = 'red',
                                        'possibly detected' = 'yellow'), name = 'score')

# order factors so possibles plot first
obs$score <- factor(obs$score, levels=levels(obs$score)[order(levels(obs$score), decreasing = TRUE)])

data.frame('x' = unique(tracks$yday[tracks$platform %in% visual_platforms]), 
           'y' = -1,
           cat = 'Sightings per day')

# determine days with trackline effort
vis_effort = data.frame('yday' = unique(tracks$yday[tracks$platform %in% visual_platforms]), 
                        'y' = -1,
                        'cat' = 'Sighting events per day')
aco_effort = data.frame('yday' = unique(tracks$yday[tracks$platform %in% acoustic_platforms]), 
                        'y' = -1,
                        'cat' = 'Detection events per day')
eff = rbind.data.frame(vis_effort,aco_effort)

# build plot --------------------------------------------------------------

# build plot

g = ggplot(obs, aes(x = yday))+
  geom_histogram(stat = "count", na.rm = T, aes_string(fill = 'score'))+
  labs(x = '', y = '')+
  fillcols+
  facet_wrap(~cat, scales="free_y", nrow = 2)+
  scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b"))+
  geom_point(data = eff, aes(x = yday, y=y), pch=45, cex = 3, col = 'blue')+
  aes(text = paste('date: ', format(as.Date(as.character(yday), "%j"), "%d-%b")))

# plotly
gg = ggplotly(g, dynamicTicks = F, tooltip = c("text", "count", "fill")) %>%
  layout(margin=list(r=120, l=70, t=40, b=70), showlegend = TRUE)
gg
