## daily_app_data ##
# quick script to grab daily data by platform for Chris

t0 = as.Date('2018-06-01')
t1 = as.Date('2018-10-01')

# read
df = readRDS('data/processed/observations.rds')

# subset
df = df[df$date >= t0 & df$date <= t1,]
df = df[df$species == 'right',]
df = df[df$lon <= -57 & df$lon >= -66,]
df = df[df$lat <= 51.5 & df$lat >= 45.5,]
df = df[df$score %in% c('definite visual', 'definite acoustic', 'possible acoustic'),]

# date vector
dv = seq(t0, t1, by = 'day')

# initialize data frame
out = data.frame(date = dv,
                 slocum_definite = rep(NA, length(dv)),
                 slocum_possible = rep(NA, length(dv)),
                 visual = rep(NA, length(dv)))
# loop
for(i in seq_along(dv)){
  
  # idate
  idate = dv[i]
  
  # date data
  tmp = df[df$date == idate,]
  
  # islocum
  out$slocum_possible[i] = nrow(tmp[tmp$platform == 'slocum' & tmp$score == 'possible acoustic',])
  out$slocum_definite[i] = nrow(tmp[tmp$platform == 'slocum' & tmp$score == 'definite acoustic',])
  
  # ivisual
  out$visual[i] = nrow(tmp[tmp$platform %in% c('vessel','plane'),])
  
}

# plot
plot(out$date, out$visual, type = 'l')
lines(out$date, out$slocum_definite, type = 'l', col = 'blue')
lines(out$date, out$slocum_possible, type = 'l', col = 'green')

# add day of week
out$weekday = as.factor(format(out$date, '%A'))

# plot daily histogram
pdf('figures/detections_by_weekday.pdf', width = 8, height = 6)

boxplot(out$slocum_definite ~ out$weekday, xlab = '', ylab = 'Detections per day')
title('LFDCS detections by weekday')
mtext(text = 'Right whale detections from June 01 to October 01 in the Southern GoSL', 
      side = 3, adj = 0, cex = 1)

dev.off()
 
# write data
write.csv(out, file = 'data/extracted/detections_by_weekday.csv', row.names = FALSE)
