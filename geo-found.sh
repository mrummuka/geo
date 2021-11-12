#!/bin/bash

#
#	Requires: curl; gpsbabel; bash or ksh;
#		  mysql (if using the gpsdrive.sql output option)
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-found.sh,v 1.34 2013/02/18 21:41:06 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Fetch a list of geocaches found by a specific user

SYNOPSIS
    `basename $PROGNAME` [options] [username]

    `basename $PROGNAME` [options] [username] [lat] [lon]

DESCRIPTION
    Fetch a list of geocaches found by a specific user.  Only unique
    caches are found (i.e. two or more logs on a cache are listed
    only once).  Archived caches have the lat/lon set to 0.0, 0.0.

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
    Show the most recent 50 caches found by Jeremy:

	geo-found -s -n50 Jeremy

    Show the most recent caches found by Jeremy that are with
    a radius of 15 miles of your home location:

	geo-found -s -r15M Jeremy

    Show the most recent caches found by Jeremy that are with
    a radius of 15 miles of a specific location:

	geo-found -s -r50 Jeremy N47.20.000 W121.30.000

    Make a FULL backup of all of my cache logs (can take awhile):

	geo-found -n9999 -L ifound -otabsep > ifound.tabsep

    Append an incremental backup of all of my cache logs:

	DIR=ifound; FILE=\$DIR.tabsep
	geo-found -n40 -L \$DIR -otabsep >> \$FILE
	gpsbabel -itabsep -f\$FILE -xduplicate,shortname -otabsep -F\$FILE

FILES
    ~/.georc
    ~/.geo/caches/

SEE ALSO
    geo-nearest, geo-newest, geo-keyword, geo-placed, geo-code, geo-waypoint,
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

LOGUSERNAME="$BYUSER"
byuser=`urlencode "$BYUSER" | tr ' ' '+' `
SEARCH="?ul=$byuser"
if [ "$BYUSER" = "$USERNAME" ]; then
    VARTIME=ifound
fi

gc_query
