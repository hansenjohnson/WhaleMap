#!/bin/bash
# Report errors in data processing

## Variables
sfile=data/processed/status.txt # status file

# get path to file
fpath=$1

# isolate file basename
fname=${fpath##*/}

# determine date
DATE=`date '+%Y-%m-%d %H:%M:%S'`

# add filename to file (if doesn't exist already)
grep -q -F "$fname" $sfile || echo $fname >> $sfile

# Extract OS name
unamestr=`uname`

# add error message (`sed` is OS specific)
if [[ "$unamestr" == 'Linux' ]]; then
	sed -i 's/.*$fname.*/$fname, ERROR ($DATE)/' $sfile
elif [[ "$unamestr" == 'Darwin' ]]; then
	sed -i '' 's/.*$fname.*/$fname, ERROR ($DATE)/' $sfile
fi
