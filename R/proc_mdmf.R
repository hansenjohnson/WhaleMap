## proc_mdmf ##
# process data from mass dmf

# input -------------------------------------------------------------------

# input
obs_url = 'https://services1.arcgis.com/7iJyYTjCtKsZS1LR/arcgis/rest/services/Species_Sighting_Public_View/FeatureServer/4/query?where=1%3D1&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnTrueCurves=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='
eff_url = 'https://services1.arcgis.com/7iJyYTjCtKsZS1LR/arcgis/rest/services/Acoustic_Monitor_Deployment_Survey_Track_Points_view/FeatureServer/0/query?where=1%3D1&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&outDistance=&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&returnAggIds=false&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnTrueCurves=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pgeojson&token='

# output
obs_ofile = 'data/interim/mdmf_obs.rds'
eff_ofile = 'data/interim/mdmf_eff.rds'

# setup -------------------------------------------------------------------

# functions
source('R/functions.R')

# read in spp and obs keys
spp_key = data.frame(
  code = c('FIWH', 'RIWH', 'MIWH', 'SEWH', 'HUWH', 'BLWH'),
  species = c('fin', 'right', 'minke', 'sei', 'humpback', 'blue'))

# sightings ---------------------------------------------------------------

# read in sightings
obs = read_sf(obs_url)

# clean up platform
obs$platform = obs$SurveyType
obs$platform[obs$platform == 'dedicated'] = 'vessel'

# process
sig = obs %>%
  st_drop_geometry() %>%
  transmute(
    time = as.POSIXct(CaptureDate/1000),
    date = as.Date(time),
    year = year(date),
    yday = yday(date),
    lat = S_LAT,
    lon = S_LONG,
    species = SPECCODE,
    score = 'sighted',
    number = NUMANIMAL,
    calves = NUMCALF,
    platform = platform,
    name = 'MDMF',
    id = paste0(date, '_', platform, '_', name),
    source = 'WhaleMap'
  )

# clean up species
mind = match(table = spp_key$code, x = sig$species)
sig$species = spp_key$species[mind]
sig = sig[which(!is.na(sig$species)),]

# update formatting
sightings = config_observations(sig)

# save
saveRDS(sightings, obs_ofile)

# effort ------------------------------------------------------------------

# read in effort
eff = read_sf(eff_url)

# process
trk = eff %>%
  st_drop_geometry() %>%
  transmute(
    time = as.POSIXct(CaptureDate/1000),
    date = as.Date(time),
    year = year(date),
    yday = yday(date),
    lat = LAT_DD,
    lon = LONG_DD,
    speed = NA,
    altitude = NA,
    platform = 'vessel',
    name = 'MDMF',
    id = paste0(date, '_', platform, '_', name),
    source = 'WhaleMap'
  )

# split and simplify
ids = unique(trk$id)
EFF = vector('list', length = length(ids))
for(ii in seq_along(ids)){
  itrk = trk %>% filter(id == ids[ii])
  EFF[[ii]] = subsample_gps(itrk)
}
out = bind_rows(EFF)

# format
tracks = config_tracks(out)

# save
saveRDS(tracks, eff_ofile)
