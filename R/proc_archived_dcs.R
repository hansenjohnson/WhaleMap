# process and save all archived dcs (glider, buoy, etc) deployment tracklines and detections

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/dcs/archived/'

# directory for output
output_dir = 'data/interim/'

# track file
track_fname = 'dcs_archived_tracks.rds'

# detection file
det_fname = 'dcs_archived_detections.rds'

# process -----------------------------------------------------------------

# read in function
source('functions/proc_dcs.R')

# process data
proc_dcs(data_dir = data_dir, output_dir = output_dir, det_fname = det_fname, track_fname = track_fname)
