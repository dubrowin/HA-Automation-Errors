#!/bin/bash

################################
## Collects Home Assistant
## trace file and search for errors
##
## Updated: Apr 15, 2025
## By: Shlomo Dubrowin
################################

################################
## Variables
################################
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/sbin/:/sbin
LOG="/tmp/$( basename "$0" )_$( date +%d%m%Y ).log"
DEBUG="Y"
TMP1="/tmp/$( basename "$0" ).1.tmp"
echo -e "\c" > $TMP1
TMP2="/tmp/$( basename "$0" ).2.tmp"
echo -e "\c" > $TMP2

BACKDIR="/tmp/ha-traces/"
REMOTEDIR="/mnt/data/supervisor/homeassistant/.storage/"
HOST="homeassistant"
RANGE=40
TO="your_email_here@foo.com"
FROM="your_email_here@foo.com"

mkdir -p $BACKDIR

################################
## Functions
################################
function Debug {
        if [ "$DEBUG" == "Y" ]; then
                if [ ! -z "$CRON" ]; then
                        # Cron, output only to log
			logger -t $( basename "$0") "$$ running $SECONDS secs: $1"
                        #echo -e "$( date +"%b %d %H:%M:%S" ) running $SECONDS secs: $1" >> $LOG
                else
                        # Not Cron, output to CLI and log
			logger -t $( basename "$0") "$$ running $SECONDS secs: $1"
                        echo -e "$( date +"%b %d %H:%M:%S" ) $$ running $SECONDS secs: $1" 
                fi
        fi
}

function EMail {
        Debug "sending via ssmtp"
        echo -e "To: $TO\nFrom: $FROM\nSubject: `hostname` HA Errors" > $TMP2
		echo "" >> $TMP2
		cat $TMP1 >> $TMP2
                ssmtp $TO < $TMP2 
}

################################
## Main Code
################################
mkdir -p $BACKDIR

Debug "scp -P 22222 root@$HOST:${REMOTEDIR}trace.saved_traces $BACKDIR"
scp -P 22222 root@$HOST:${REMOTEDIR}trace.saved_traces $BACKDIR

#Debug "rsync -avz --remove-source-files -e 'ssh -p 22222' $BACKDIR root@$HOST:/mnt/data/supervisor/backup/"
#rsync -avz --remove-source-files -e 'ssh -p 22222' $BACKDIR root@$HOST:/mnt/data/supervisor/backup/

Debug "Look for errors in file"
#FAILCOUNT=`grep script_execution ${BACKDIR}trace.saved_traces | grep -vic "finished"`
FAILCOUNT=`grep script_execution ${BACKDIR}trace.saved_traces | grep -vic "finished\|failed_conditions"`
TOTCOUNT=`grep script_execution ${BACKDIR}trace.saved_traces -c`
Debug "FAILCOUNT $FAILCOUNT out of $TOTCOUNT Traces recorded"

if [ "$FAILCOUNT" != "0" ]; then
	Debug "Errors found, collecting additional data and sending email"
	#for START in $( grep -n script_execution ${BACKDIR}trace.saved_traces | grep -vi finished | cut -d : -f 1 ); do
	for START in $( grep -n script_execution ${BACKDIR}trace.saved_traces | grep -vi "finished\|failed_conditions" | cut -d : -f 1 ); do
		let "END = $START + $RANGE"
		sed -n -e "$START,${END}p" ${BACKDIR}trace.saved_traces | grep "script_execution\|friendly_name\|last_triggered" | grep -vi "finished" >> $TMP1
	done

	Debug "Emailing Report"
	EMail
fi

Debug "Finished"
