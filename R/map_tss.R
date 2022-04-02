## proc_tss ##
# process traffic separation scheme data

# setup -------------------------------------------------------------------

# libraries
suppressPackageStartupMessages(library(rgdal))
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(raster))

# canadian tss reader
wrangle_tss = function(file_name, lon_col, lat_col, lstart, lend, pstart, pend){
  # This function will, with some supervision, parse a 'tss file' to extract the lat-lon positions of lines and polygons in a consistent format. It will also optionally attempt to plot the processed tss coordinates.
  # file_name -> path to input file ('.csv')
  # lon_col -> column index (integer) of csv where longitude values are stored
  # lat_col -> column index (integer) of csv where latitude values are stored
  # l/pstart, l/pend -> start and stop row indices of polygons (p) or lines (l)
  # plot_tss -> switch to plot
  # fig_dir -> directory to save figures

  # read in data
  f = read.csv(file = file_name, header = F, colClasses = 'character')
  
  # determine location name
  name = file_path_sans_ext(basename(file_name))
  
  # polygons
  if(pend-pstart>0){
    p = f[pstart:pend,]
    plon = as.numeric(p[,lon_col])
    plat = as.numeric(p[,lat_col])
    
    pd = data.frame(lon = plon, lat = plat, name = name, type = 'polygons')
    
    # configure map
    clon = mean(pd$lon, na.rm = T) 
    clat = mean(pd$lat, na.rm = T)
    span = 6 * 111 * diff(range(pd$lat, na.rm = T))
  } else {
    pd = NULL
  }
  
  # lines
  if(lend-lstart>0){
    l = f[lstart:lend,]
    llon = as.numeric(l[,lon_col])
    llat = as.numeric(l[,lat_col])
    
    ld = data.frame(lon = llon, lat = llat, name = name, type = 'lines')
    
    # configure map
    clon = mean(ld$lon, na.rm = T) 
    clat = mean(ld$lat, na.rm = T)
    span = 6 * 111 * diff(range(ld$lat, na.rm = T))
    
  } else {
    ld = NULL
  }
  
  # combine into data frame list
  out = list(tss_lines = ld, tss_polygons = pd)
  
  return(out)
}

# process canadian TSS ----------------------------------------------------

# initialize list for gathering output
TSS = list()

# anticosti
ifile = 'data/raw/tss/Anticosti_and_more.csv'
TSS[[1]] = wrangle_tss(ifile, lon_col = 1, lat_col = 2, lstart = 1, lend = 36, pstart = 38, pend = 103)

# fundy
ifile = 'data/raw/tss/Bay_of_Fundy.csv'
TSS[[2]] = wrangle_tss(ifile, lon_col = 2, lat_col = 3, lstart = 28, lend = 44, pstart = 2, pend = 28)

# belle isle
ifile = 'data/raw/tss/Belle_Isle.csv'
TSS[[3]] = wrangle_tss(ifile, lon_col = 5, lat_col = 6, lstart = 65, lend = 112, pstart = 4, pend = 57)

# boston
ifile = 'data/raw/tss/Boston.csv'
TSS[[4]] = wrangle_tss(ifile, lon_col = 1, lat_col = 2, lstart = 6, lend = 16, pstart = 0, pend = 0)

# chedabucto
ifile = 'data/raw/tss/Chedabucto_bay.csv'
TSS[[6]] = wrangle_tss(ifile, lon_col = 1, lat_col = 2, lstart = 2, lend = 24, pstart = 27, pend = 48)

# chesapeake
ifile = 'data/raw/tss/Chesapeake_Bay.csv'
TSS[[7]] = wrangle_tss(ifile, lon_col = 1, lat_col = 2, lstart = 6, lend = 32, pstart = 0, pend = 0)

# gulf
ifile = 'data/raw/tss/Gulf.csv'
TSS[[8]] = wrangle_tss(ifile, lon_col = 4, lat_col = 5, lstart = 45, lend = 79, pstart = 5, pend = 43)

# halifax
ifile = 'data/raw/tss/Halifax.csv'
TSS[[9]] = wrangle_tss(ifile, lon_col = 2, lat_col = 3, lstart = 43, lend = 66, pstart = 2, pend = 38)

# northumberland
ifile = 'data/raw/tss/Northumberland_Strait.csv'
TSS[[12]] = wrangle_tss(ifile, lon_col = 3, lat_col = 4, lstart = 4, lend = 20, pstart = 0, pend = 0)

# placentia
ifile = 'data/raw/tss/Placentia_Bay.csv'
TSS[[13]] = wrangle_tss(ifile, lon_col = 9, lat_col = 10, lstart = 49, lend = 106, pstart = 3, pend = 48)

# portland
ifile = 'data/raw/tss/Portland.csv'
TSS[[14]] = wrangle_tss(ifile, lon_col = 2, lat_col = 3, lstart = 6, lend = 10, pstart = 0, pend = 0)

# st georges bay
ifile = 'data/raw/tss/St_Georges_Bay.csv'
TSS[[15]] = wrangle_tss(ifile, lon_col = 4, lat_col = 5, lstart = 29, lend = 43, pstart = 6, pend = 22)

# st lawrence river - needs to be customized because it's taken from a shape file

pfile = 'data/raw/tss/StLawrenceRiver_from_Shapefile.csv'
ifile = paste0(file_path_sans_ext(pfile), '-corr.csv')
  
# pre-processing (stick an NA row between each id)
f = read.csv(pfile, header = T)
f$id = as.factor(f$id)
sf = split(f, f$id)
lst = lapply(sf, function(x) rbind(x, rep(NA,3)))
out = do.call(rbind, lst)
write.csv(x = out, file = ifile, row.names = F)

# processing
TSS[[16]] = wrangle_tss(ifile, lon_col = 1, lat_col = 2, lstart = 1, lend = 133, pstart = 133, pend = 274)

# combine canadian tss ----------------------------------------------------

# combine all lines
tl1 = lapply(TSS, function(x) x$tss_lines)
tl1[sapply(tl1, is.null)] <- NULL
tl2 = lapply(tl1, function(x) rbind(x, rep(NA,4)))
tss_lines = do.call(rbind, tl2)

# combine all polygons
tp1 = lapply(TSS, function(x) x$tss_polygons)
tp1[sapply(tp1, is.null)] <- NULL
tp2 = lapply(tp1, function(x) rbind(x, rep(NA,4)))
tss_polygons = do.call(rbind, tp2)

# process US tss ----------------------------------------------------------

# read in data
tss_usa = readOGR('data/raw/tss/shippinglanes/')

# crop to bounding box
tss_usa = crop(tss_usa, extent(-82,-67, 26, 60))

# remove redundant layers
tss_usa = tss_usa[!tss_usa$THEMELAYER %in% c('Speed Restrictions/Right Whales', 'Area to be Avoided'),]

# test --------------------------------------------------------------------

# # test with leaflet
# leaflet() %>%
#   addTiles() %>%
#   addPolylines(tss_lines$lon, tss_lines$lat, weight = .5) %>%
#   addPolygons(tss_polygons$lon, tss_polygons$lat, weight = .5) %>%
#   addPolygons(data = tss_usa, weight = .5)

# save --------------------------------------------------------------------

# save output
save(tss_polygons, tss_lines, tss_usa, file = 'data/processed/tss.rda')
