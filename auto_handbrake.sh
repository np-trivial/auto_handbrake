#!/usr/bin/env bash

HANDBRAKECLI=/usr/local/bin/HandBrakeCLI
LOG=/var/log/auto_handbrake.log
TARGETPATH="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Movies"
# rip everthing longer that $MINDURATION seconds
# set to "" to just rip what HandBrake detects as the "main feature"
MINDURATION="300"

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
		echo "DVD already ripped, ejecting"
		eject /dev/cd0
		continue
	fi

	echo "New DVD; ripping"
	# give the drive time to calm before trying to rip
	sleep 10

	# rip it
	# log that we ripped this title
	# eject disk

	# if there's anything over an hour long, use "main feature" mode
	ismovie=`$HANDBRAKECLI -i /dev/cd0 -t 0  --min-duration 3600 |&  egrep "^[+] title [[:digit:]]+" | egrep -o "[[:digit:]]+"`

	# rip just main title if $MINDURATION == 0
	if [ -z $ismovie ]; then
		echo "Ripping all titles $MINDURATION seconds or longer"
		for i in `$HANDBRAKECLI -i /dev/cd0 -t 0  --min-duration 300 |&  egrep "^[+] title [[:digit:]]+" | egrep -o "[[:digit:]]+"`; do 
			echo HandBrake $DVDTITLE-Title$i;
			$HANDBRAKECLI -i /dev/cd0 -o "$TARGETPATH/$DVDTITLE-Title$i".mp4 --main-feature --preset="High Profile" -N eng &>>/var/log/HandBrakeCLI.log 
		done;
		echo $DVDTITLE >> $LOG
		eject /dev/cd0
	else	
		echo "Ripping main feature"
		$HANDBRAKECLI -i /dev/cd0 -o "$TARGETPATH/$DVDTITLE".mp4 --main-feature --preset="High Profile" -N eng &>>/var/log/HandBrakeCLI.log && echo $DVDTITLE >> $LOG && eject /dev/cd0
	fi
done
