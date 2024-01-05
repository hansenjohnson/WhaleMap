## write_xml ##
# write xml feeds

# input -------------------------------------------------------------------

# xml filenames
xml_filenames = 'data/processed/xml_filenames.rda'

# setup -------------------------------------------------------------------

source('R/functions.R')

# read in xml info
load('data/processed/xml_filenames.rda')

# function to generate xmls
make_xml = function(obs, fname){
  
  # fix mom/calf
  obs$momcalf = ifelse(obs$calves == 1, 'Yes', 'No')
  
  # create a blank file
  invisible(file.create(fname))
  write('<SAS>', file = fname)
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
    write(obs_str, file = fname, append = TRUE)
  }
  
  # write last line
  write('</SAS>', file = fname, append = TRUE)
  
  # move to server_index
  cp_cmd = paste0('cp -r ', fname, ' ../server_index/data/', basename(fname))
  system(cp_cmd)
  
}

# process public ----------------------------------------------------------

# define time range
t0 = Sys.Date() - 365
t1 = Sys.Date()

# read and filter observations
obs_pub = readRDS('data/processed/observations.rds') %>%
  dplyr::filter(!is.na(lat) & !is.na(lon) & !is.na(date) & !is.na(species) & !is.na(score)) %>%
  dplyr::filter(date >= t0 & date <= t1) %>%
  dplyr::filter(species == 'right') %>%
  dplyr::filter(score %in% c('possible acoustic', 'definite acoustic', 'definite visual')) %>%
  dplyr::filter(source != 'WhaleInsight') %>%
  dplyr::filter(platform == "plane" & name == "noaa_twin_otter" | platform == 'opportunistic')

make_xml(obs = obs_pub, fname = xml_public)

# process private ---------------------------------------------------------

# define time range
t0 = Sys.Date() - 365
t1 = Sys.Date()

# read and filter observations
obs_prv = readRDS('data/processed/observations.rds') %>%
  dplyr::filter(!is.na(lat) & !is.na(lon) & !is.na(date) & !is.na(species) & !is.na(score)) %>%
  dplyr::filter(date >= t0 & date <= t1) %>%
  dplyr::filter(species == 'right') %>%
  dplyr::filter(!source %in% c('WhaleInsight','NARWC'))

make_xml(obs = obs_prv, fname = xml_private)
