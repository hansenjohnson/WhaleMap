## proc_nefsc_vessel_live ##
# process sightings and tracklines from NEFSC vessel(s)

# input -------------------------------------------------------------------

# directory to look for files
data_dir = 'data/raw/nefsc_vessel/live/'

# directory for output
trk_ofile = 'data/interim/nefsc_vessel_live_eff.rds'
obs_ofile = 'data/interim/nefsc_vessel_live_obs.rds'

# setup -------------------------------------------------------------------

source('R/functions.R')
source('R/proc_nefsc_vessel.R')

# process -----------------------------------------------------------------

proc_nefsc_vessel(data_dir = data_dir, trk_ofile = trk_ofile, obs_ofile = obs_ofile)
