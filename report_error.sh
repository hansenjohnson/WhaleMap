#!/bin/bash
# Report errors in data processing

## Variables
sfile=data/processed/status.txt # status file

# get path to file
path=$1

# isolate file basename
fname=${path##*/}

# add filename to file (if doesn't exist already)
grep -q -F "$fname" $sfile || echo $fname >> $sfile

# add error message
sed -i "s/.*$fname.*/$fname, error/" $sfile
