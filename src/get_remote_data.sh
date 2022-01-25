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
# printf "\n*** Checking DFO Google Drive ***\n\n"
# rclone sync whalemapdata:"WhaleMapData_Master/2021/" "2021_whalemapdata/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync CCS aerial data Google drive
printf "\n*** Checking CCS Google Drive ***\n\n"
rclone sync drive:"WhaleMap_CCS" "ccs/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync NEAq aerial data Google drive
printf "\n*** Checking NEAq Aerial Google Drive ***\n\n"
# rclone sync drive:"WhaleMap_NEAq_aerial" "2021_neaq_aerial/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync NOAA aerial data Google drive
printf "\n*** Checking NOAA Google Drive ***\n\n"
printf "2021 Flight data \n\n"
rclone sync drive:"WhaleMap" "2021_noaa_twin_otter/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync NOAA aerial data Google drive
printf "\n*** Checking SEUS Google Drive ***\n\n"
rclone sync drive:"4_Data for SEUS Whale Map" "seus/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync NEAq vessel data
printf "\n*** Checking NEAq SNE Google Drive ***\n\n"
rclone sync drive:"WhaleMap-2022 NEAq SNE Surveys" "2022_neaq_sne/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync CWI/NEAq vessel data Google drive
# printf "\n*** Checking NEAq/CWI Google Drive ***\n\n"
# rclone sync drive:"WhaleMap_2021_NEAq_CWI" "2021_neaq_cwi/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync MICS vessel data Google drive
# printf "\n*** Checking MICS Google Drive ***\n\n"
# rclone sync drive:"Right Whale data 2021" "2021_mics/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# printf "\n*** Checking UNB Dropbox ***\n\n"
# rclone sync drive:"WhaleMap-UNB" "unb/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf --exclude *.HEIC --exclude *.png --exclude *.PNG

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
