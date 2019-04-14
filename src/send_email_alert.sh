#!/bin/bash
# send email alert after WhaleMap error

# define date
DATE=`date '+%Y-%m-%d %H:%M:%S'`

# Email message text
subject="WhaleMap Error: $DATE"
recipients="hansen.johnson@dal.ca"
from="hansen.johnson@dal.ca"

# Define temporary file name
email_file="error_email.txt"

# Extract OS name
unamestr=`uname`

# Define OS-specific paths
if [[ "$unamestr" == 'Linux' ]]; then
	DESTDIR=/srv/shiny-server/WhaleMap # server
	SSHDIR=/home/hansen
elif [[ "$unamestr" == 'Darwin' ]]; then
	DESTDIR=/Users/hansenjohnson/Projects/WhaleMap # local
	SSHDIR=/Users/hansenjohnson
fi

# Move to project directory
cd ${DESTDIR}

# Find error lines
error=$(grep 'ERROR' data/processed/status.txt)

if [ -z "$error" ]
then # if no error

  # remove email file
  if [ -f "$email_file" ]
  then
    rm $email_file
  fi

else # if error exists
      if [ ! -f "$email_file" ]
      then # if no temp file

          # create temp error file
          touch $email_file

          # add lines to file
          echo "Subject: $subject" >> $email_file
          echo "From: $from" >> $email_file
          echo "" >> $email_file
          echo "Check WhaleMap! There's a problem here:" >> $email_file
          echo "$error" >> $email_file

          # send email
          sendmail "$recipients" < $email_file

          # mail sent message
          echo "Error message sent at: $DATE"

      fi
fi
