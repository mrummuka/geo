#!/bin/bash

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Correct the coords of cache(s) on the gc.com site

SYNOPSIS
    `basename $PROGNAME` [options] [gcid lat lon] ...

DESCRIPTION
    Correct the coordinates of cache(s) on the gc.com site.  It can take
    arguments or read from a file.  It can work on traditional, multi,
    wherigo, mystery, etc., caches, unlike the GC interface.

EXAMPLES
    Correct GC288HG:

	$ geo-correct-coords GC288HG n44.51.202 w93.45.232

    Correct GC numbers in ~/.geo-mystery:

	$ geo-correct-coords <  ~/.geo-mystery

OPTIONS
    -D lvl	Debug level

SEE ALSO
    $WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Process the options
#
read_rc_file

DEBUG=0
while getopts "D:h?" opt
do
	case $opt in
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi
HTMLPAGE=$TMP.page
CRUFT="$CRUFT $HTMLPAGE"
logged_in=0

process() {
    gcid=$1
    lat=$2
    lon=$3
    if [ $logged_in = 0 -a $DEBUG -lt 9 ]; then
	gc_login "$USERNAME" "$PASSWORD"
	logged_in=1
    fi
    sleep 2

    URL="https://www.geocaching.com/seek/cache_details.aspx?wp=$gcid"
    debug 2 "$gcid: curl $URL #Fetch..."
    if [ $DEBUG -lt 9 ]; then
	curl $CURL_OPTS -L -s -A "$UA" -b $COOKIE_FILE \
            "$URL" > $HTMLPAGE
	sleep 2
    fi
    userToken=` grep "userToken = '" $HTMLPAGE \
		| sed -e "s/.* = '//" -e "s/'.*//" `
    #echo $userToken

    URL="$GEOS/seek/cache_details.aspx/SetUserCoordinate"
    debug 2 "$gcid: curl $URL #update..."
    curl -m 30 -s -A "$UA" -b $COOKIE_FILE \
	-H "Accept: application/json" -H "Content-type: application/json" \
	-X POST \
	-d "{\"dto\":{\"data\":{\"lat\":$LAT,\"lng\":$LON},\"ut\":\"$userToken\"}}" \
	"$URL" > $HTMLPAGE

    if [ $? != 0 ]; then
	echo "$gcid: 30 second timeout! Check make sure it's been corrected!"
	logged_in=0
    else
	RC=`grep '"Message"' $HTMLPAGE | sed -e 's/.*"Message":"//' -e 's/".*//' `
	if [ "$RC" != "" ]; then
	    error "$GCID: $RC"
	fi
	debug 2 "$gcid: done."
    fi
}

#
#	Main Program
#
if [ $# = 0 ]; then
    while read GCID LAT LON extra; do
	case "$GCID" in
	GC*)	;;
	*)	continue;;
	esac

	case "$LAT" in
	[uU][nN][kK]*)	continue;;
	esac

	LAT=`latlon $LAT`
	LON=`latlon $LON`
	debug 1 "process $GCID $LAT $LON"
	process $GCID $LAT $LON
    done 
else
    if [ $# -lt 3 ]; then
	usage
    fi
    while [ $# -ge 3 ]; do
	GCID=$1; shift 1
	case "$1" in
	N|S)
	    if [ $# -ge 6 ]; then
		# Allow cut and paste from geocaching.com cache page
		# N 44° 58.630 W 093° 09.310
		LAT=`echo "$1$2.$3" | tr -d '\260\302' `
		LAT=`latlon $LAT`
		LON=`echo "$4$5.$6" | tr -d '\260\302' `
		LON=`latlon $LON`
		shift 6
	    else
		error "Illegal lat/lon: $*"
	    fi
	    ;;
	*)
	    LAT=`latlon $1`
	    LON=`latlon $2`
	    shift 2
	    ;;
	esac
	process $GCID $LAT $LON
    done
fi
