#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-placed.sh,v 1.29 2013/02/18 21:41:06 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Fetch a list of geocaches placed by a user

SYNOPSIS
    `basename $PROGNAME` [options] [username]

    `basename $PROGNAME` [options] [username] [lat] [lon]

DESCRIPTION
    Fetch a list of geocaches placed by a specific user.

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
    List the most recent 50 caches placed by dyl1231:

	geo-placed -s -n50 dyl1231

    List the most recent caches placed by dyl1231 that are with
    a radius of 15 miles of your home location:

	geo-placed -s -r15M dyl1231

    List the most recent caches placed by dyl1231 that are with
    a radius of 15 miles of a specific location:

	geo-placed -s -r50 dyl1231 N47.20.000 W121.30.000

    Display a map of the 20 newest caches placed by dyl1231:

	geo-placed -omap,-a2 -F dyl1231

    Make a backup copy of all of my caches placed (can take awhile):

	geo-placed -n999 -H descdir -L logdir -otabsep > placed.tabsep

FILES
    ~/.georc
    ~/.geo/caches/

SEE ALSO
    geo-found, geo-nearest, geo-newest, geo-keyword, geo-code, geo-waypoint,
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
UPDATE_URL=$WEBHOME/geo-found
UPDATE_FILE=geo-found.new
EXCLUDE='_NoThInG_'	# Make more sense to not exclude unavails for this query

read_rc_file

#
#       Process the options
#
BYUSER="$USERNAME"

gc_getopts "$@"
shift $?

if [ $FOUND = 0 ]; then
    error "Option -f is not allowed."
fi

#
#	Main Program
#
case "$#" in
3)	BYUSER="$1"
	LAT=`latlon $2`
	LON=`latlon $3`
	;;
1)	BYUSER="$1";;
0)	;;
*)	usage;;
esac

byuser=`echo "$BYUSER" | sed -e 's/\&/%26/g' -e 's/ /+/g' `
SEARCH="?u=$byuser"
VARTIME=placed

LOGUSERNAME="[^<]*"
gc_query
