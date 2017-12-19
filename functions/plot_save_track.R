plot_save_track = function(tracks, file){
  source('functions/plot_track.R')
  
  # determine track file name
  trk_file = gsub(pattern = 'data/raw/',replacement = 'figures/', paste0(file_path_sans_ext(file), '.png'))
  
  # create output directory
  if(!dir.exists(dirname(trk_file))) dir.create(dirname(trk_file), recursive = T)
  
  # save file
  png(trk_file, width = 5, height = 5, units = 'in', res = 100)
    plot_track(tracks)
    mtext(basename(file), side = 3, adj = 0)
  dev.off()
}