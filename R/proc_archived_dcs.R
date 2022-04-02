# process and save all archived dcs (glider, buoy, etc) deployment tracklines and detections

# user input --------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/dcs/archived/'

# directory for output
output_dir = 'data/interim/'

# track file
track_fname = 'dcs_archived_eff.rds'

# detection file
det_fname = 'dcs_archived_obs.rds'

# setup -------------------------------------------------------------------

# read in function
source('R/proc_dcs.R')

# process -----------------------------------------------------------------

# process data
proc_dcs(data_dir = data_dir, output_dir = output_dir, det_fname = det_fname, track_fname = track_fname)
