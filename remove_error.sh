#!/bin/bash
# Remove errors in data processing

## Variables
sfile=status.txt # status file

# get path to file
path=$1

# isolate file basename
fname=${path##*/}

# determine date
DATE=`date '+%Y-%m-%d %H:%M:%S'`

# add completion timestamp
sed -i "s/.*$fname.*/$fname, $DATE/" $sfile
