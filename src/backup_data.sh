#!/bin/bash
# Daily WhaleMap data backup

# Define hostname
HOSTNAME=`hostname`

# Define OS-specific paths
if [[ "$HOSTNAME" == 'AZE-WHALEMAP1'  ]]; then # server

	# Move to project directory (on server)
	cd /srv/shiny-server/WhaleMap

elif [[ "$HOSTNAME" != 'AZE-WHALEMAP1'  ]]; then
	
	# Move to project directory (on personal machine)
	cd ~/Projects/WhaleMap

fi

# Define backup dir
BKDIR="backups" 

# Get numeric day
DDATE=`date '+%u'`

# Define folder path
ODIR="$BKDIR/$DDATE"

# Delete existing dir
rm -r $ODIR

# Make backup dir
mkdir -p $ODIR

# Copy raw data to backup dir
cp -r data/raw $ODIR

# Get timestamp
TSTMP=`date '+%Y-%m-%d %H:%M:%S'`

# Define readme file
RMFILE="$ODIR/README.txt"

# Write file for timestamp
touch $RMFILE

# Write timestamp to backup dir
echo "WhaleMap data backup created at" >> $RMFILE
echo $TSTMP >> $RMFILE

# remove raw data backups
rm -r $ODIR/raw/backups/

# remove raw narwc data
rm -r $ODIR/raw/narwc/