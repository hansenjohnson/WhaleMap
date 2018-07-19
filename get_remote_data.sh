#!/bin/bash
# download survey data from remote repository

## Define variables ##
PROJDIR=/srv/shiny-server/WhaleMap/ # main project directory (server)
# PROJDIR=~/Projects/WhaleMap/ # main project directory (local)
DATADIR=${PROJDIR}/data/raw/ # raw data directory

# Move to data directory
cd ${DATADIR}

# Make backup directory
mkdir -p backups

# Sync Canadian aerial data Google drive
printf "\n*** Checking DFO Google Drive ***\n\n"
rclone sync whalemapdata:"WhaleMapData_Master/" "2018_whalemapdata/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.mp4

# Sync NOAA 2018 aerial data Google drive
printf "\n*** Checking NOAA Google Drive ***\n\n"
rclone sync drive:"2018/2018 NEFSC Survey Data/Flights/" "2018_noaa_twin_otter/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.mp4

# Sync NEAq 2018 vessel data Dropbox
printf "\n*** Checking NEAq CWI Dropbox ***\n\n"
rclone sync dropbox:"NEAq_CWI Effort_2018" "2018_neaq_cwi/" --backup-dir backups -v --exclude *.JPG --exclude *.mp4

# Sync MICS 2018 vessel data Dropbox
printf "\n*** Checking MICS Dropbox ***\n\n"
rclone sync dropbox:"Right Whale 2018" "2018_mics_sightings/" --backup-dir backups -v --exclude *.JPG --exclude *.mp4

# move to project directory
cd ${PROJDIR}

# get live WHOI/Dal acoustic detections (dcs)
printf "\n*** Checking DAL/WHOI acoustic detections ***\n\n"
bash get_live_dcs.sh

# update WhaleMap
printf "\n*** Updating WhaleMap ***\n\n"
make

# completion message
printf "\n*** WhaleMap updated :) ***\n\n"
