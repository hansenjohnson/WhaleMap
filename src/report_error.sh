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

# add error message
sed -i '' 's/.*$fname.*/$fname, ERROR ($DATE)/' $sfile
