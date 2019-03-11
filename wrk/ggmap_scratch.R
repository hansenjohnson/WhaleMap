library(ggmap)

obs = readRDS('data/processed/observations.rds')
sono = readRDS('data/processed/sonobuoys.rds')
trk = readRDS('data/processed/tracks.rds')

ulat = 49
llat = 46
ulon = -62
llon = -65

# subset

sono = subset(sono, lat < ulat & lat > llat & 
                lon < ulat & lon > llon & 
                year == '2018')

obs = subset(obs, date %in% unique(sono$date) & 
              species == 'right' &
              name == 'noaa_twin_otter' & 
              lat < ulat & lat > llat & 
              lon < ulat & lon > llon)
obs$date = as.factor(obs$date)

trk = subset(trk, date %in% unique(sono$date) & 
               name == 'noaa_twin_otter' & 
               lat < ulat & lat > llat & 
               lon < ulat & lon > llon)
trk$date = as.factor(trk$date)
trk = trk[order(trk$time),]

bmap = get_map(location = c(mean(obs$lon, na.rm = TRUE), mean(obs$lat, na.rm = TRUE)),
               maptype = "satellite", source = "google", zoom = 8)

ggm = ggmap(bmap)

ggplot() +
  geom_point(aes(x = lon, y = lat),
             data = trk, colour = 'brown') +
  geom_point(aes(x = lon, y = lat),
             data = obs) +
  geom_point(aes(x = lon, y = lat),
             data = sono, shape = 3, colour = 'red') +
  facet_wrap(~ date, scales = "free")


ggm +
  geom_point(aes(x = lon, y = lat),
            data = obs, colour = 'brown') +
  facet_wrap(~ date)
