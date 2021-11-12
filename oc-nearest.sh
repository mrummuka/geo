#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: oc-nearest.sh,v 1.14 2013/02/18 21:41:07 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch a list of nearest geocaches from opencaching.com

SYNOPSIS
	`basename $PROGNAME` [options]

	`basename $PROGNAME` [options] lat lon

DESCRIPTION
	Fetch a list of nearest geocaches from opencaching.com.

	Requires:
	    curl	http://curl.haxx.se/

EOF
	oc_usage
	cat << EOF

EXAMPLES
	Add nearest 50 caches to a GpsDrive SQL database

	    oc-nearest -n50 -f -s -S

	Purge the existing SQL database of all geocaches, and fetch
	200 fresh ones...

	    oc-nearest -S -P -s -n200

	Include cross-listed (i.e. gc.com) caches

	    oc-nearest -c -s

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint, oc-newest,
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
UPDATE_URL=$WEBHOME/oc-nearest
UPDATE_FILE=oc-nearest.new

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
LON=`latlon $LON`
SEARCH="center=$LAT,$LON"

oc_query
