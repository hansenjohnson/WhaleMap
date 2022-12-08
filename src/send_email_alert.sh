#!/bin/bash
# send email alert after WhaleMap error

# Extract OS name
unamestr=`uname`

# Define OS-specific paths
if [[ "$USER" == 'wmpadmin' ]]; then # server

	# Move to project directory
	cd /srv/shiny-server/WhaleMap

	# write and send email
	Rscript R/write_error_email.R

elif [[ "$USER" != 'wmpadmin' ]]; then
	echo "No error email sent - will only send from server"
fi
