## write_public_xml ##
# write public xml feed

# input -------------------------------------------------------------------

# xml files
public_xml = 'feed/WhaleMap.xml'

# setup -------------------------------------------------------------------

suppressPackageStartupMessages(library(xml2))
source('R/functions.R')

# create folder
xml_dir = dirname(public_xml)
if(!dir.exists(xml_dir)){dir.create(xml_dir,recursive = TRUE)}

# process -----------------------------------------------------------------

# define time range
t0 = Sys.Date() - 365
t1 = Sys.Date()

# read and filter observations
obs = readRDS('data/processed/observations.rds') %>%
  dplyr::filter(!is.na(lat) & !is.na(lon) & !is.na(date) & !is.na(species) & !is.na(score)) %>%
  dplyr::filter(species == 'right') %>%
  dplyr::filter(date >= t0 & date <= t1) %>%
  dplyr::filter(score %in% c('possible acoustic', 'definite acoustic', 'definite visual')) %>%
  dplyr::filter(source != 'WhaleInsight') %>%
  dplyr::filter(platform == 'opportunistic')

# fix mom/calf
obs$momcalf = ifelse(obs$calves == 1, 'Yes', 'No')

# create xml for each data point
tmp = xml_new_root('SAS')

# create a blank file
file.create(public_xml)
write('<SAS>', file = public_xml)
for(ii in 1:nrow(obs)){
  
  iobs = obs[ii,]
  
  # extract data
  t_id = paste0('id=\"',ii,'\"')
  t_time = paste0('sightdate=\"',iobs$time,'\"')
  t_lat = paste0('lat=\"',format(iobs$lat, nsmall = 6),'\"')
  t_lon = paste0('lon=\"',format(iobs$lon, nsmall = 6),'\"')
  t_number = paste0('groupsize=\"',iobs$number,'\"')
  t_platform = paste0('category=\"',iobs$platform,'\"')
  t_score = paste0('description=\"',iobs$score,'\"')
  t_momcalf = paste0('momcalf=\"',iobs$momcalf,'\"')
  t_org = paste0('obs_org=\"',iobs$name,'\"')
  
  # assemble text string
  obs_str = paste('<sight', t_id, t_time, t_lat, t_lon, t_number, t_platform, t_score, t_momcalf, t_org, '></sight>')
  
  # append to xml
  write(obs_str, file = public_xml, append = TRUE)
}

# write last line
write('</SAS>', file = public_xml, append = TRUE)
