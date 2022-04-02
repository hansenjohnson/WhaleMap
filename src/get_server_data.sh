#!/bin/bash
# download processed data from WhaleMap server

# Define processed data directory
DATADIR=/Users/hansenjohnson/Projects/WhaleMap/data/processed/

# Move to data directory
cd ${DATADIR}

# Copy contents
rsync -rtv whalemapvm:/srv/shiny-server/WhaleMap/data/processed/ .
