#!/bin/bash
# wakeup.sh - Wakeup script to set the computer to wakeup from
# suspened/hibernate states at specified time
# Note : This is substantially old and written a long time ago
# 
# Author Anish Shankar <rndanish[AT]gmail[DOT]com>
# 
# Description:
# 
# The program is basically a interface to add a value to:
# /sys/class/rtc/rtc0/wakealarm
# It mainly interfaces to check and print appropriate
# messages for the date format , duration , etc.
# suppourts relative as well as absoulte dates just as
# suppourted by date since it is finally parsed by the
# date command
# e.g wakeup.sh +3 min +4 hours +2min - 3 sec
#     wakeup.sh 2011-04-03 14:00:00
#     wakeup.sh Fri Mar  4 16:04:38 IST-230 2011 + 3 Hours
#     


ALARM_PATH="/sys/class/rtc/rtc0/wakealarm"
DATE=$@
#if [ -z "$@" ]
if [ -z "$DATE" ]
then
	echo -e "Usage:" $0 "DATE \n(DATE in format YYYY-MM-DD HH:MM:SS or as understood by date)" 1>&2
	exit 1
else
	if date  --date "$DATE" "+%F %T" 2>/dev/null 1>/dev/null
	then
		if touch $ALARM_PATH 2>/dev/null 
		then
			echo 0 > $ALARM_PATH 
			#To Convert Relative Dates if any as well as Time ZONES to absolute localtime date
			DATE=$(date --date "$DATE" "+%F %T")
			echo `date -u --date "$DATE" +%s` > $ALARM_PATH
			if [ -z "`cat $ALARM_PATH`" ]
			then
				echo "No ALARM Set Possibly Already Passed Time" 1>&2
				exit 1
			else
				DURATION=$(expr $(date -u --date "$DATE" +%s) - $(date -u --date "`date \"+%F %T\"`" +%s))
				((DUR_SEC=DURATION%60))
				((DURATION/=60))
				((DUR_MIN=DURATION%60))
				((DURATION/=60))
				((DUR_HOUR=DURATION%24))
				((DURATION/=24))
				((DUR_DAY=DURATION))
				echo -n "Alarm Succesfully Set for"
				if [ "$DUR_DAY" -gt 0 ]; then echo -n " $DUR_DAY Days";fi
				if [ "$DUR_HOUR" -gt 0 ]; then echo -n " $DUR_HOUR Hours";fi
				if [ "$DUR_MIN" -gt 0 ]; then echo -n " $DUR_MIN Minutes";fi
				echo " $DUR_SEC Seconds From now"
				exit 0
			fi
		else
			echo "Permission Denied need to be root" 1>&2
			exit 1
		fi
	else
		echo "Invalid DATE format" 1>&2
		echo -e "Usage:" $0 "DATE \n(DATE in format YYYY-MM-DD HH:MM:SS)" 1>&2
		exit 1
	fi
fi
