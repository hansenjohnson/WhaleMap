#!/bin/bash
# download survey data from remote repository

# Extract OS name
unamestr=`uname`

# Define OS-specific paths
if [[ "$unamestr" == 'Linux' ]]; then
	DESTDIR=/srv/shiny-server/WhaleMap # server
	SSHDIR=/home/hansen
elif [[ "$unamestr" == 'Darwin' ]]; then
	DESTDIR=/Users/hansenjohnson/Projects/WhaleMap # local
	SSHDIR=/Users/hansenjohnson
fi

# Determine raw data directory
DATADIR=${DESTDIR}/data/raw/

# Move to data directory
cd ${DATADIR}

# Make backup directory
mkdir -p backups

# Sync Canadian aerial data Google drive
printf "\n*** Checking DFO Google Drive ***\n\n"
# rclone sync whalemapdata:"WhaleMapData_Master/2018/" "2018_whalemapdata/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf
rclone sync whalemapdata:"WhaleMapData_Master/2019/" "2019_whalemapdata/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf

# Sync NOAA 2018 aerial data Google drive
printf "\n*** Checking NOAA Google Drive ***\n\n"
# printf "2018 Flight data \n\n"
# rclone sync drive:"2018/2018 NEFSC Survey Data/Flights/" "2018_noaa_twin_otter/" --drive-skip-gdocs --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf
# printf "2018 Sonobuoy data \n\n"
# rclone sync drive:"2018/2018 Sonobuoy recordings/sonobuoy_metadata/" "noaa_sonobuoys/" --drive-formats csv --backup-dir backups -v --exclude *.wav --exclude *.txt
printf "2019 Flight data \n\n"
rclone sync drive:"2019/2019 NEFSC Survey Data/Flights/" "2019_noaa_twin_otter/" --drive-shared-with-me --drive-skip-gdocs --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync NEAq 2018 vessel data Dropbox
# printf "\n*** Checking NEAq CWI Dropbox ***\n\n"
# rclone sync dropbox:"NEAq_CWI Effort_2018" "2018_neaq_cwi/" --backup-dir backups -v --exclude *.JPG --exclude *.mp4

# Sync MICS 2018 vessel data Dropbox
# printf "\n*** Checking MICS Dropbox ***\n\n"
# rclone sync dropbox:"Right Whale 2018" "2018_mics_sightings/" --backup-dir backups -v --exclude *.JPG --exclude *.mp4

# Sync JASCO server
# printf "\n*** Checking JASCO Server ***\n\n"
# rsync -rtve "ssh -i $SSHDIR/.ssh/mykey" whalemap@142.176.15.238:/home/whalemap/ jasco/ --exclude=".*"

# move to project directory
cd ${DESTDIR}

# get live WHOI/Dal acoustic detections (dcs)
printf "\n*** Checking DAL/WHOI acoustic detections ***\n\n"
bash src/get_live_dcs.sh

# update WhaleMap
printf "\n*** Updating WhaleMap ***\n\n"
make

# check for errors and send emails
# printf "\n*** Checking for errors and sending email alerts ***\n\n"
# bash send_email_alert.sh

printf "\n*** Update complete :) ***\n\n"
