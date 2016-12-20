#!/bin/bash

HANDBRAKECLI=/usr/local/bin/HandBrakeCLI
LOG=/var/log/auto_handbrake.log
TARGETPATH=/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Movies

if [ $UID -ne 0 ]; then
	echo "Must run as root; exiting"
	exit;
fi

while [ 1 ]; do
	sleep 10 	# sleep need to be at beginning because of mid-loop escapes
	#DVDTITLE=`$HANDBRAKECLI -i /dev/cd0 --scan 2>&1 | egrep -o "DVD Title: .*" | sed "s/DVD Title: //"`
	DVDTITLE=`isoinfo -d -i /dev/cd0 | grep "Volume id" | cut -b "12-"`
	echo "DVD Title: $DVDTITLE"
	if [ -z $DVDTITLE ]; then
		# can't get the DVD title. Likely, there's nothing in the drive
		continue
	fi

	# If return is 1, then grep was successful, but string was not there
	# for anything else, exit
	fgrep -qs "$DVDTITLE" $LOG 
	if [ $? != 1 ] ; then
		# title was not in list of previously ripped dvds
		eject /dev/cd0
		continue
	fi

	#echo "rip it"
	# give the drive time to calm before trying to rip
	sleep 10

	# rip it
	# log that we ripped this title
	# eject disk

	# working version
	#$HANDBRAKECLI -i /dev/cd0 -o $TARGETPATH/"$DVDTITLE".mp4 --main-feature --preset="Android Tablet" &>>/var/log/HandBrakeCLI.log && echo $DVDTITLE >> $LOG && eject /dev/cd0
	# an attempt to add subtitles to the working version
	$HANDBRAKECLI -i /dev/cd0 -o $TARGETPATH/"$DVDTITLE".mp4 --main-feature --preset="High Profile" -N eng &>>/var/log/HandBrakeCLI.log && echo $DVDTITLE >> $LOG && eject /dev/cd0
	
	#$HANDBRAKECLI -i /dev/cd0 -o $TARGETPATH/"$DVDTITLE".mp4 --preset="High Profile" &>/var/log/HandBrakeCLI.log 
done
