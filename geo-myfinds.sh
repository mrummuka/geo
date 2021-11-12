#!/bin/bash

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Schedule a Pocket Query containing your finds

SYNOPSIS
	`basename $PROGNAME` [options]

DESCRIPTION
	Schedule a Pocket Query containing your finds.  GC limits them
	to every 3 days.

	Crontab Entry:

	    # 3AM on the 1st, ..., 25th of the month (i.e. 4 days)
	    0 3  1,5,9,13,17,21,25 * * geo-myfinds
	    0 11 1,5,9,13,17,21,25 * * geo-pqdownload -n "My*" -z 

	Requires:
	    - A premium subscriber login at http://www.geocaching.com.
	    - curl		http://curl.haxx.se/

OPTIONS
        -u username     Username for http://www.geocaching.com
        -p password     Password for http://www.geocaching.com
        -U              Retrieve latest version of this script
        -D lvl          Debug level [$DEBUG]

	Defaults can also be set with variables in file \$HOME/.georc:

	    PASSWORD=password;  USERNAME=username;

SEE ALSO
	geo-demand, geo-newest, geo-found, geo-placed, geo-nearest,
	geo-pqdownload,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/geo-myfinds
UPDATE_FILE=geo-myfinds.new

read_rc_file

#
#       Process the options
#

while getopts "u:p:D:Uh?-" opt
do
    case $opt in
    u)	USERNAME="$OPTARG";;
    p)	PASSWORD="$OPTARG";;
    D)	DEBUG="$OPTARG";;
    U)	echo "Getting latest version of this script..."
	curl $CURL_OPTS -o$UPDATE_FILE "$UPDATE_URL"
	chmod +x "$UPDATE_FILE"
	echo "Latest version is in $UPDATE_FILE"
	exit
	;;
    h|\?|-) usage;;
    esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
DBGCMD_LVL=2
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

#
#	Login to gc.com
#
if [ $NOCOOKIES = 1 ]; then
    CRUFT="$CRUFT $COOKIE_FILE"
fi
if [ "$DEBUG" -lt 3 ]; then
    gc_login "$USERNAME" "$PASSWORD"
fi

#
#	Post the pocket query form
#
PQURL="https://www.geocaching.com/pocket/default.aspx"
REPLY=$TMP-reply.html; CRUFT="$CRUFT $REPLY"

if [ "$DEBUG" -lt 3 ]; then
    # Get viewstate
    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	"$PQURL" > $REPLY

    gc_getviewstate $REPLY
    get_value DateTimeBegin $REPLY
    get_value DateTimeEnd $REPLY
    echo=
else
    echo=echo
fi

$echo dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	$viewstate \
	-d "ctl00%24ContentBody%24PQListControl1%24hidIds=" \
	-d "ctl00%24ContentBody%24PQDownloadList%24hidIds=" \
	-d "ctl00%24ContentBody%24PQListControl1%24btnScheduleNow=Add to Queue" \
	-d "__EVENTTARGET=" \
	-d "__EVENTARGUMENT=" \
	"$PQURL" > $REPLY
