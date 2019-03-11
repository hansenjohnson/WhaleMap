#!/bin/bash
# build static map using latest data for display on main webpage

# move to map directory
cd /srv/shiny-server/WhaleMap

# run build script
Rscript build_static_map.R
