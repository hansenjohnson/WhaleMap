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
rclone sync whalemapdata:"WhaleMapData_Master/2020/" "2020_whalemapdata/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync NOAA aerial data Google drive
printf "\n*** Checking NOAA Google Drive ***\n\n"
printf "2020 Flight data \n\n"
rclone sync drive:"WhaleMap" "2020_noaa_twin_otter/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync Hawkins 2020 vessel data Google
# printf "\n*** Checking Hawkins Drive ***\n\n"
# rclone sync drive:"2020_Nick Hawkins" "2020_niha/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf --exclude *.HEIC --exclude *.png --exclude *.PNG

# Sync NEAq vessel data Dropbox
# printf "\n*** Checking NEAq CWI Dropbox ***\n\n"
# rclone sync drive:"WhaleMap-NEAq" "2020_neaq/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf --exclude *.HEIC --exclude *.png --exclude *.PNG

# Sync UNB opportunistic vessel data Dropbox
# printf "\n*** Checking UNB Dropbox ***\n\n"
# rclone sync drive:"WhaleMap-UNB" "2020_unb/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf --exclude *.HEIC --exclude *.png --exclude *.PNG

# move to project directory
cd ${DESTDIR}

# get live WHOI/Dal acoustic detections (dcs)
printf "\n*** Checking DAL/WHOI acoustic detections ***\n\n"
bash src/get_live_dcs.sh

# update WhaleMap
printf "\n*** Updating WhaleMap ***\n\n"
make

# check for errors and send emails
printf "\n*** Checking for errors and sending email alerts ***\n\n"
bash src/send_email_alert.sh

printf "\n*** Update complete :) ***\n\n"
