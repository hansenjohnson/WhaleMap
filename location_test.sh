#!/bin/bash
# Determine location
if [[ "$OSTYPE"=='darwin14.5.0' ]]; then
	echo /Users/hansenjohnson/Projects/WhaleMap # local
	echo /Users/hansenjohnson
else
	echo /srv/shiny-server/WhaleMap # server
	echo /home/hansen
fi
