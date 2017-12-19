#!/bin/bash
# rclone data from Google Drive

# Move to data directory
cd Projects/WhaleMap/data/raw/

# Sightings data
rclone sync drive:2017_narw_sightings/ 2017_sightings/ --drive-formats csv --backup-dir backups

# NOAA Twin Otter GPS
rclone sync drive:Aerial_Surveys_GPS/NOAA_Twin_Otter NOAA_Twin_Otter/ --backup-dir backups

# DFO Twin Otter GPS
rclone sync drive:Aerial_Surveys_GPS/DFO_Twin_Otter DFO_Twin_Otter/ --backup-dir backups

# TC Dash-8
rclone sync drive:Aerial_Surveys_GPS/Dash-8 Dash-8/ --backup-dir backups