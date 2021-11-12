#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: oc-newest.sh,v 1.5 2013/02/18 21:41:07 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch a list of newest geocaches from opencaching.com

SYNOPSIS
	`basename $PROGNAME` [options] [country] [state]

	`basename $PROGNAME` [options] [state]

	`basename $PROGNAME` [options] [state] lat lon

DESCRIPTION
	Fetch a list of newest geocaches from opencaching.com.

	Requires:
	    curl	http://curl.haxx.se/

EOF
	oc_usage
	cat << EOF

EXAMPLES
	Add newest 50 caches to a GpsDrive SQL database

	    oc-newest -n50 -f -s -S

	Purge the existing SQL database of all geocaches, and fetch
	200 fresh ones...

	    oc-newest -S -P -s -n200

	Include cross-listed (i.e. gc.com) caches

	    oc-newest -c -s

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-oc"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/oc-newest
UPDATE_FILE=oc-newest.new

read_rc_file

#
#       Process the options
#

oc_getopts "$@"
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
3)      STATE="$1"
        LAT=`latlon $2`
        LON=`latlon $3`
        ;;
2)      STATE="$2"
        COUNTRY="$1"
        ;;
1)	STATE="$1";;
0)
        ;;
*)
        usage
        ;;
esac

# http://www.batchgeo.com/lookup/?q=mn

LAT=`latlon $LAT`
LON=`latlon $LON`
SEARCH="center=$LAT,$LON"
SEARCH="$SEARCH&order_by=published_dttm&Authorization=5S86wxVR5v2XVGu6"

oc_query
