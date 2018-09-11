#!/bin/bash
# Determine location
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
	echo /srv/shiny-server/WhaleMap # server
	echo /home/hansen
elif [[ "$unamestr" == 'Darwin' ]]; then
	echo /Users/hansenjohnson/Projects/WhaleMap # local
	echo /Users/hansenjohnson
fi
