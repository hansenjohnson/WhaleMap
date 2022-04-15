## get_dcs ##
# get dcs data from whoi platforms

# input -------------------------------------------------------------------

# process live data only
live_only = TRUE

# remove hidden data (only run occasionally)
remove_hidden = FALSE

# dcs raw data
dcs_data_dir = 'data/raw/dcs/'

# active url
lv_url = 'http://dcs.whoi.edu/deployed_platforms.csv'

# archived list
dl_file = 'data/raw/dcs/deployment_list.csv'

# setup -------------------------------------------------------------------

source('R/functions.R')
if(!dir.exists(dcs_data_dir)){dir.create(dcs_data_dir)}

# extract project directory
pdir = getwd()

# check for new deployments -----------------------------------------------

# read list of deployed platforms
lv = read.csv(lv_url, stringsAsFactors = F)

# read in list of known deployments
dl = read.csv(dl_file, stringsAsFactors = F)

# compare
new_deps = lv$url[!lv$url %in% dl$url]

# add missing deployments
if(length(new_deps) > 0){
  
  for(ii in seq_along(new_deps)){
    
    # extract base url
    u = as.character(new_deps[ii])
    
    # read in platform data
    p = read.csv(paste0(u,'/platform.csv'),stringsAsFactors = F)
    
    # extract platform type
    pt = p$platform_type
    if(pt == 'slocum_glider'){pt = 'slocum'}
    
    # define detection file
    ptfile = paste0(u,'/manual_analysis.csv')
    
    # check if file exists
    if(!file.exists(ptfile)){
      message('No manual analysis file found for: ', ptfile)
      message('Skipping...\n')
      next
    }
    
    # read in data
    d = read.csv(ptfile, stringsAsFactors = F)  
    
    # extract start date
    s = as.Date(substr(as.character(d$datetime_utc[1]), 0, 8), '%Y%m%d')
    
    # construct id
    id = paste(s, pt, p$platform_name, sep = '_')
    
    # extract lat/lon
    lat = d$lat[1]
    lon = d$lon[1]
    
    # guess display status
    if(lat < 0 | lon < -80 | !pt %in% c('buoy', 'slocum')){
      display = F
    } else {
      display = T
    }
    
    # append to deployment list
    nl = data.frame(
      status = 'live',
      id = id,
      url = u,
      display = display
    )
    dl = rbind(dl,nl)
    
    # store detection data
    ddir = paste0(dcs_data_dir,'live',id)
    if(!dir.exists(ddir)){dir.create(path = ddir, recursive = T)}
    write.csv(x = d, file = paste0(ddir, '/manual_analysis.csv'), row.names = F)
    
    # update message
    message('Adding new deployment: ', id)
  }
  
  # save updated detection list
  write.csv(dl, file = dl_file, row.names = F)
}

# check deployment status -------------------------------------------------

# deployments to archive based on removal from live list
la1 = which(!(dl$url %in% lv$url) & dl$status == 'live')

# deployments in live folder
in_live = basename(list.dirs(paste0(dcs_data_dir, 'live'),recursive = F))

# deployments in live list
ls_live = dl$id[dl$status == 'live' & dl$display]

# deployments to archive based on 
la2 = which(!in_live %in% ls_live)

# deployments to archive
to_archive = c(la1,la2)

if(length(to_archive) > 0){
  message('Archiving deployments:\n', paste(dl$id[to_archive], collapse = '\n'))
  
  # move data directories
  for(ii in seq_along(to_archive)){
    ia = to_archive[ii]
    old_dir = paste0(pdir, '/',dcs_data_dir,'live/',dl$id[ia])
    new_dir = gsub('live','archived',old_dir)
    system(paste0('mv ', old_dir, ' ', new_dir))
  }
  
  dl$status[to_archive] = 'archived'
  write.csv(dl, file = dl_file, row.names = F)
}

# get data ----------------------------------------------------------------

if(live_only){
  dll = dl[dl$status == 'live' & dl$display,]  
} else {
  dll = dl[dl$display,]
}

# download data via wget system call
for(ii in 1:nrow(dll)){
  
  # define url and data path
  URL = paste0(dll$url[ii], '/manual_analysis.csv')
  DIR = paste0(paste0(pdir, '/', dcs_data_dir, dll$status[ii], '/', dll$id[ii]), '/')
  
  # wget system call
  wget = paste0('wget -N ',URL,' -P ', DIR)
  
  # execute system call
  system(wget)
  
}

# remove hidden data ------------------------------------------------------

if(remove_hidden){
  no_display = which(!dl$display)
  
  if(length(no_display) > 0){
    for(ii in seq_along(no_display)){
      ia = no_display[ii]
      rdir = paste0(paste0(pdir, '/', dcs_data_dir, dl$status[ia], '/', dl$id[ia]), '/')
      system(paste0('rm -r ', rdir))
    }
  }
}

# fix folder contents -----------------------------------------------------

# deployments in live folder
in_live = basename(list.dirs(paste0(dcs_data_dir, 'live'),recursive = F))

# deployments in live list
ls_live = dl$id[dl$status == 'live' & dl$display]

# check which need to be moved
to_move = which(!in_live %in% ls_live)

if(length(to_move)>0){
  message('Moving deployments:\n', paste(in_live[to_move], collapse = '\n'))
  for(ii in seq_along(to_move)){
    old_dir = paste0(pdir, '/',dcs_data_dir,'live/',in_live[to_move[ii]])
    new_dir = gsub('live','archived',old_dir)
    system(paste0('mv ', old_dir, ' ', new_dir))
  }
}
