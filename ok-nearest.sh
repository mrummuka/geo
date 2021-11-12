#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: ok-nearest.sh,v 1.8 2013/02/18 21:41:07 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch a list of nearest geocaches from opencaching.us

SYNOPSIS
	`basename $PROGNAME` [options]

	`basename $PROGNAME` [options] lat lon

DESCRIPTION
	Fetch a list of nearest geocaches from opencaching.us.

	Requires:
	    curl	http://curl.haxx.se/

EOF
	ok_usage
	cat << EOF

EXAMPLES
	Add nearest 50 caches to a GpsDrive SQL database

	    ok-nearest -n50 -f -s -S

	Purge the existing SQL database of all geocaches, and fetch
	200 fresh ones...

	    ok-nearest -S -P -s -n200

	Nearest in UK:

	    ok-nearest -s -E OKBASE=http://www.opencaching.org.uk n53.5 w1.5

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint, ok-newest,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-ok"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/ok-nearest
UPDATE_FILE=ok-nearest.new

read_rc_file

#
#       Process the options
#

ok_getopts "$@"
shift $?

#
#	Main Program
#
case "$#" in
6)
        # Cut and paste from geocaching.com cache page
        # N 44° 58.630 W 093° 09.310
        LAT=`echo "$1$2.$3" | tr -d '\260\302' `
        LAT=`latlon $LAT`
        LON=`echo "$4$5.$6" | tr -d '\260\302' `
        LON=`latlon $LON`
        ;;
2)
        LAT=`latlon $1`
        LON=`latlon $2`
        ;;
0)
        ;;
*)
        usage
        ;;
esac

LAT=`latlon $LAT`
LATNS=`degdec2mindec $LAT NS | cut -c 1 `
LATH=`degdec2mindec $LAT NS | sed -e "s/.//" -e "s/\..*//" `
LATMIN=`degdec2mindec $LAT | sed "s/[^.]*\.//" `
LON=`latlon $LON`
LONEW=`degdec2mindec $LON EW | cut -c 1 `
LONH=`degdec2mindec $LON EW | sed -e "s/.//" -e "s/\..*//" `
LONMIN=`degdec2mindec $LON | sed "s/[^.]*\.//" `
SEARCH="searchto=searchbydistance&sort=bydistance"
SEARCH="$SEARCH&latNS=$LATNS&lat_h=$LATH&lat_min=$LATMIN"
SEARCH="$SEARCH&lonEW=$LONEW&lon_h=$LONH&lon_min=$LONMIN"
#echo "$SEARCH"

ok_query
