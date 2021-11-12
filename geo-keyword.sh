#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-keyword.sh,v 1.12 2013/02/18 21:41:06 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Fetch geocaches with keyword(s)

SYNOPSIS
    `basename $PROGNAME` [options] keyword ...

DESCRIPTION
    Fetch geocaches with keyword(s).

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
    geo-keyword Big Stone Lake

FILES
    ~/.georc
    ~/.geo/caches/

SEE ALSO
    geo-nearest, geo-newest, geo-found, geo-placed, geo-code, geo-map,
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
UPDATE_URL=$WEBHOME/geo-nearest
UPDATE_FILE=geo-nearest.new

read_rc_file

#
#       Process the options
#

gc_getopts "$@"
shift $?

#
#	Main Program
#
[ $# -gt 0 ] || error "Need at least one keyword to search for (-? for help)."
STR=$(echo "$@" | tr ' ' '+')
SEARCH="?key=$STR&submit4=Find"
gc_query
