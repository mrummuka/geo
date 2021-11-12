#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-newest.sh,v 1.45 2018/07/08 17:47:09 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Fetch a list of newest geocaches

SYNOPSIS
    `basename $PROGNAME` [options] [country] [state]

    `basename $PROGNAME` [options] [state] 

    `basename $PROGNAME` [options] [state] [lat] [lon]

DESCRIPTION
    Fetch a list of newest geocaches.  "state" is only avaliable for USA.

    Requires:
        A premium member (\$30/yr) OR a basic member (free) login at:
             http://www.geocaching.com
        Visit a cache page and click the "Download to EasyGPS" link at least
        once so you can read and agree to the license terms.  Otherwise, you
        will not get any waypoint data.

	curl		http://curl.haxx.se/
	gpsbabel	http://gpsbabel.sourceforge.net/

EOF
	gc_usage
	cat << EOF

NOTE
    A basic member will get caches very slow (20 cache pages per minute)
    because we have to get the actual cache pages.  They will be stored in:
        ~/.geo/caches/GCXXXX.html.
    Of course, after running this command, geo-html2gpx could be run.

EXAMPLES
    Add newest 50 caches to a GpsDrive SQL database

	geo-newest -n50 -f -s -S MN

    Purge the existing SQL database of all geocaches, and fetch
    200 fresh ones...

	geo-newest -S -P -s -n200 MN

    Create a GPX file of all caches in MN, including all logs.  This
    will take several hours to run, and should only be run at night.

	geo-newest -X "" -n2000 -D1 -H html MN > junk
	geo-html2gpx -b html/*.html > all-mn.gpx

    Fetch country Iraq:

	geo-newest -s Iraq

    Fetch country Germany, state Berlin:

	geo-newest -s Germany Berlin

    Fetch country Germany, state Berlin by code:

	geo-newest -s c79 s137

    Fetch country "bonaire, sint eustatius and saba" with multiple states:

	$ geo-newest "bonaire, sint eustatius and saba" bonaire
	GC1FJVW 12.19538 -68.27433 Geocache-regular
	GCJPPB 12.20538 -68.31377 Geocache-regular
	GC316E 12.10817 -68.25967 Geocache-regular

	$ geo-newest "bonaire, sint eustatius and saba" "sint eustatius"
	GC10RX5 17.47677 -62.97547 Geocache-earth

    Fetch by search:

	geo-newest -f -q unknown

	Also, tx=webcam, tx=earth, tx=multi, tx=event, tx=virtual, tx=letter,
	tx=unknown, tx=trad (tx=reg is an alias).

FILES
    ~/.georc
    ~/.geo/caches/

SEE ALSO
    geo-countries-states
    geo-nearest, geo-found, geo-placed, geo-keyword, geo-code, geo-map,
    geo-waypoint,
    $WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/geo-newest
UPDATE_FILE=geo-newest.new
STATE=MN
COUNTRY=

read_rc_file

#
#       Process the options
#

gc_getopts "$@"
shift $?

#
#	Main Program
#
case "$#" in
8)	STATE="$2"
        COUNTRY="$1"
        # Cut and paste from geocaching.com cache page
        # N 44° 58.630 W 093° 09.310
        LAT=`echo "$3$4.$5" | tr -d '\260\302' `
        LAT=`latlon $LAT`
        LON=`echo "$6$7.$8" | tr -d '\260\302' `
        LON=`latlon $LON`
        ;;
4)      STATE="$2"
	COUNTRY="$1"
	LAT=`latlon $3`
	LON=`latlon $4`
	;;
3)	STATE="$1"
	LAT=`latlon $2`
	LON=`latlon $3`
	;;
2)      STATE="$2"
	COUNTRY="$1"
	;;
1)	STATE="$1";;
0)	;;
*)	usage;;
esac

state=`echo $STATE | tr '[A-Z]' '[a-z]'`
case "$state" in
#include "geo-newest-cs"
s[0-9]*)	id=` echo $state | tr -c -d '[0-9]' `;;
c[0-9]*)	cid=` echo $state | tr -c -d '[0-9]' `;;
*)		error "Unknown state '$STATE'";;
esac

if [ "$id" != "" -a "$cid" != "" ]; then
    SEARCH="?country_id=$cid&state_id=$id"
elif [ "$id" != "" ]; then
    SEARCH="?state_id=$id"
else
    SEARCH="?country_id=$cid&as=1"
fi

VARTIME=placed

#
#	Do cfilter stuff
#
if [ "$POCKETQUERY" != "" ]; then
    case "$POCKETQUERY" in
    webcam)	POCKETQUERY="31d2ae3c-c358-4b5f-8dcd-2185bf472d3d";;
    earth*)	POCKETQUERY="c66f5cf3-9523-4549-b8dd-759cd2f18db8";;
    multi*)	POCKETQUERY="a5f6d0ad-d2f2-4011-8c14-940a9ebf3c74";;
    event)	POCKETQUERY="69eb8534-b718-4b35-ae3c-a856a55b0874";;
    virtual)	POCKETQUERY="294d4360-ac86-4c83-84dd-8113ef678d7e";;
    letter*)	POCKETQUERY="4bdd8fb2-d7bc-453f-a9c5-968563b15d24";;
    unknown)	POCKETQUERY="40861821-1835-4e11-b666-8d41064d03fe";;
    trad*)	POCKETQUERY="32bc9333-5e52-4957-b0f6-5a2c8fc7b257";;
    reg*)	POCKETQUERY="32bc9333-5e52-4957-b0f6-5a2c8fc7b257";;
    esac

    SEARCH="$SEARCH&cFilter=$POCKETQUERY&children=n"

    if [ $FOUND = 0 ]; then
	SEARCH="$SEARCH&ex=1"
    fi
    POCKETQUERY=
fi

gc_query
