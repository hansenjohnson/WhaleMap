} else {

  message('Using raw data (not f_file) in: \n', idir)

  # gps tracklines ----------------------------------------------------------

  # find gps file
  gps_file = list.files(idir, pattern = '.gps$', full.names = TRUE, recursive = TRUE)[1]

  # read in data (method below is slower but more robust to errors in gps file)
  textLines = readLines(gps_file)
  counts = count.fields(textConnection(textLines), sep=",")
  trk = read.table(text=textLines[counts == 7], header=FALSE, sep=",")

  # select and rename important columns
  trk = data.frame(trk$V1, trk$V3, trk$V2, trk$V4, trk$V6)
  colnames(trk) = c('time', 'lon', 'lat', 'speed', 'altitude')

  # remove columns without timestamp
  trk = trk[which(!is.na(trk$time)),]

  # add timestamp
  trk$time = as.POSIXct(trk$time, format = '%d/%m/%Y %H:%M:%S', tz="UTC", usetz=TRUE)

  # subsample (use default subsample rate)
  tracks = subsample_gps(gps = trk)

  # add metadata
  tracks$date = as.Date(tracks$time)
  tracks$yday = yday(tracks$date)
  tracks$year = year(tracks$date)
  tracks$platform = 'plane'
  tracks$name = 'noaa_twin_otter'
  tracks$id = paste(tracks$date, tracks$platform, tracks$name, sep = '_')

  # add to list
  TRK[[i]] = tracks

  # sig sightings -----------------------------------------------------------

  # find sig file
  sig_files = list.files(idir, pattern = '.sig$', full.names = TRUE, recursive = TRUE)

  iSIG = list()
  for(j in seq_along(sig_files)){

    # skip empty files
    if(file.size(sig_files[j]) == 0) next

    # read in data
    sig = read.table(sig_files[j], sep = ',')

    # assign column names
    colnames(sig) = c('transect', 'unk1', 'unk2', 'time', 'observer', 'declination', 'species', 'number', 'confidence', 'bearing', 'unk5', 'unk6', 'comments', 'side', 'lat', 'lon', 'calf', 'unk7', 'unk8', 'unk9', 'unk10')

    # remove final estimates
    sig = sig[!grepl(pattern = 'fin est', x = sig$comments, ignore.case = TRUE),]

    # if they exist, only include actual positions
    if(nrow(sig[grepl(pattern = 'ap', x = sig$comments, ignore.case = TRUE),])>0){
      sig = sig[grepl(pattern = 'ap', x = sig$comments, ignore.case = TRUE),]
    }

    # remove columns without timestamp
    sig = sig[which(!is.na(sig$time)),]

    # add timestamp
    sig$time = as.POSIXct(sig$time, format = '%d/%m/%Y %H:%M', tz="UTC", usetz=TRUE)

    # add metadata
    sig$date = as.Date(sig$time)
    sig$yday = yday(sig$date)
    sig$year = year(sig$date)
    sig$score = 'sighted'
    sig$platform = 'plane'
    sig$name = 'noaa_twin_otter'
    sig$id = paste(sig$date, sig$platform, sig$name, sep = '_')

    # initialize species column
    sig$sp_code = as.character(sig$species)
    sig$species = NA

    # add species identifiers
    sig$sp_code = toupper(sig$sp_code)
    sig$species[sig$sp_code == 'EG'] = 'right'
    sig$species[sig$sp_code == 'MN'] = 'humpback'
    sig$species[sig$sp_code == 'BB'] = 'sei'
    sig$species[sig$sp_code == 'BP'] = 'fin'
    sig$species[sig$sp_code == 'BA'] = 'minke'
    sig$species[sig$sp_code == 'BM'] = 'blue'

    # drop unknown codes
    sig = sig[which(!is.na(sig$species)),]

    # keep important columns
    sig = sig[,c('time','lat','lon','date', 'yday','species','score','number','year','platform','name','id')]

    # add to list
    iSIG[[j]] = sig
  }

  # combine multiple sightings file
  SIG[[i]] = do.call(rbind.data.frame, iSIG)
}