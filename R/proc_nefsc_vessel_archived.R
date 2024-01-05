## proc_nefsc_vessel_archived ##
# process sightings and tracklines from NEFSC vessel(s)

# input -------------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/nefsc_vessel/archive/'

# directory for output
trk_ofile = 'data/interim/nefsc_vessel_archived_eff.rds'
obs_ofile = 'data/interim/nefsc_vessel_archived_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
source('R/proc_nefsc_vessel.R')

# process -----------------------------------------------------------------

proc_nefsc_vessel(data_dir = data_dir, trk_ofile = trk_ofile, obs_ofile = obs_ofile)
