#!/bin/bash
# download survey data from remote repository

# get hostname
HOSTNAME=`hostname`

# Define OS-specific paths
if [[ "$HOSTNAME" == 'AZE-WHALEMAP1' ]]; then
	DESTDIR=/srv/shiny-server/WhaleMap # server
	SSHDIR=/home/wmpadmin
elif [[ "$HOSTNAME" != 'AZE-WHALEMAP1' ]]; then
  DESTDIR=/Users/${USER}/Projects/WhaleMap # local
	SSHDIR=/Users/${USER}
fi

# Determine raw data directory
DATADIR=${DESTDIR}/data/raw/

# Move to data directory
cd ${DATADIR}

# Make backup directory
mkdir -p backups

# Sync data from Whale Insight
printf "\n*** Checking WhaleInsight Google Drive ***\n\n"
rclone sync whalemapdata:"WhaleMapData_Exchange/trk_from_dfo.csv" "wi/live/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG
rclone sync whalemapdata:"WhaleMapData_Exchange/obs_from_dfo.csv" "wi/live/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync CCS aerial data Google drive
printf "\n*** Checking CCS Google Drive ***\n\n"
rclone sync drive:"WhaleMap_CCS" "ccs/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync NEAq aerial data Google drive
printf "\n*** Checking NEAq Aerial Google Drive ***\n\n"
rclone sync drive:"WhaleMap_NEAq_aerial" "neaq/aerial/" --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync NEAq vessel data Google drive
printf "\n*** Checking NEAq Vessel Google Drive ***\n\n"
rclone sync drive:"2022 GSL  (NEAq) Data for WhaleMap" "neaq/vessel/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.mp3 --exclude *.MP3 --exclude *.pdf --exclude *.MPG

# Sync NERW aerial data Google drive
printf "\n*** Checking NERW Google Drive ***\n\n"
rclone sync wm_drive:"2023/2023 NEFSC Survey Data/Flights/WhaleMap NEFSC 2023" "nerw/live" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync NERW aerial data Google drive
printf "\n*** Checking NEFSC vessel Google Drive ***\n\n"
rclone sync drive:"Whalemap_NEFSC_vessel" "nefsc_vessel/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync SERW aerial data Google drive
printf "\n*** Checking SERW Google Drive ***\n\n"
rclone sync drive:"4_Data for SEUS Whale Map" "serw/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# Sync NEAq vessel data
printf "\n*** Checking NEAq SNE Google Drive ***\n\n"
rclone sync drive:"WhaleMap-2022 NEAq SNE Surveys" "neaq/sne/" --drive-shared-with-me --drive-formats csv --backup-dir backups -v --exclude *.JPG --exclude *.jpg --exclude *.mp4 --exclude *.pdf

# move to project directory
cd ${DESTDIR}

# get live WHOI/Dal acoustic detections (dcs)
printf "\n*** Checking DAL/WHOI acoustic detections ***\n\n"
Rscript R/get_dcs.R

# get US DMA data
printf "\n*** Checking US DMA data ***\n\n"
Rscript R/map_dma.R

# update WhaleMap
printf "\n*** Updating WhaleMap ***\n\n"
make

# check for errors and send emails
printf "\n*** Checking for errors and sending email alerts ***\n\n"
bash src/send_email_alert.sh

printf "\n*** Update complete :) ***\n\n"
