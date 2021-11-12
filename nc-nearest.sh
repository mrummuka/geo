#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: nc-nearest.sh,v 1.4 2013/02/18 21:41:07 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch a list of nearest geocaches

SYNOPSIS
	`basename $PROGNAME` [options]

	`basename $PROGNAME` [options] [lat] [lon]

DESCRIPTION
	Fetch a list of neearest geocaches from navicache.com.

	Requires:
	    curl	http://curl.haxx.se/

EOF
	nc_usage
	cat << EOF

EXAMPLES
	Add nearest 50 caches to a GpsDrive SQL database

	    nc-nearest -n50 -f -s -S MN

	Purge the existing SQL database of all geocaches, and fetch
	200 fresh ones...

	    nc-nearest -S -P -s -n200 MN

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint, nc-newest,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-nc"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/nc-nearest
UPDATE_FILE=nc-nearest.new
STATE=MN

read_rc_file

#
#       Process the options
#

nc_getopts "$@"
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

CMD=nearest
nc_query
