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

# Extract OS name
unamestr=`uname`

# add completion timestamp (`sed` is OS specific)
if [[ "$unamestr" == 'Linux' ]]; then
	sed -i 's/.*$fname.*/$fname, $DATE/' $sfile
elif [[ "$unamestr" == 'Darwin' ]]; then
	sed -i '' 's/.*$fname.*/$fname, $DATE/' $sfile
fi
