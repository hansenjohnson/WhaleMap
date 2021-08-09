#!/bin/bash
# Remove errors in data processing

## Variables
sfile=data/processed/status.txt # status file

# get path to file
fpath=$1

# isolate file basename
fname=${fpath##*/}

# determine date
DATE=`date '+%Y-%m-%d %H:%M:%S'`

# create output text
otext="$fname $DATE"

# add completion timestamp (using perl vs sed for cross-platform compatibility)
perl -pi -e "s/.*$fname.*/$otext/" $sfile
