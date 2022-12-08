#!/bin/bash
# download data from WhaleMap server

# Define processed data directory
DATADIR=/Users/${USER}/Projects/WhaleMap/data/

# Move to data directory
cd ${DATADIR}

# Copy contents
rsync -rtv wmpadmin@20.122.3.103:/srv/shiny-server/WhaleMap/data/ .
