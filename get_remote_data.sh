#!/bin/bash
# download survey data from remote repository

# Move to project data directory
cd ~/Projects/WhaleMap/data/raw/

# NOAA twin otter gps data
rclone sync drive:Aerial_Surveys_GPS/NOAA_Twin_Otter/ noaa_twin_otter_tracks/ --backup-dir backups

# DFO twin otter gps data
rclone sync drive:Aerial_Surveys_GPS/DFO_Twin_Otter/ dfo_twin_otter_tracks/ --backup-dir backups

# TC Dash-8 gps data
rclone sync drive:Aerial_Surveys_GPS/Dash-8/ tc_dash8_tracks/ --backup-dir backups

# Sightings
rclone sync drive:2017_narw_sightings/ 2017_sightings/ --drive-formats csv
