#!/bin/bash
# Determine location
unamestr=`uname`
if [[ "$unamestr"=='Darwin' ]]; then
	echo /Users/hansenjohnson/Projects/WhaleMap # local
	echo /Users/hansenjohnson
elif [[ "$unamestr"=='Linux' ]]; then
	echo /srv/shiny-server/WhaleMap # server
	echo /home/hansen
fi
