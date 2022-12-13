#!/bin/bash
# send email alert after WhaleMap error

# get hostname
HOSTNAME=`hostname`

# Define OS-specific paths
if [[ "$HOSTNAME" == 'AZE-WHALEMAP1'  ]]; then # server

	# Move to project directory
	cd /srv/shiny-server/WhaleMap

	# write and send email
	Rscript R/write_error_email.R

elif [[ "$HOSTNAME" != 'AZE-WHALEMAP1'  ]]; then
	echo "No error email sent - will only send from server"
fi
