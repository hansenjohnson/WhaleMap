#!/bin/bash
# send WhaleMap email test

# get hostname
HOSTNAME=`hostname`

# Define OS-specific paths
if [[ "$HOSTNAME" == 'AZE-WHALEMAP1'  ]]; then # server

	# Move to project directory
	cd /srv/shiny-server/WhaleMap

	# write and send email
	Rscript R/write_test_email.R

elif [[ "$HOSTNAME" != 'AZE-WHALEMAP1'  ]]; then
	echo "No test email sent - will only send from server"
fi