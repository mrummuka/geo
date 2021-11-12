#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: gpx-unfound.sh,v 1.4 2013/02/18 21:41:07 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Filter a GPX file removing found caches

SYNOPSIS
	`basename $PROGNAME` [options] finder-name < in.gpx > out.gpx

DESCRIPTION
	Filter a GPX file removing found caches.

	Requires:
	    curl	http://curl.haxx.se/

OPTIONS
        -D lvl  Debug level

EXAMPLES
	Filter caches unfound by "rickrich":

	    geo-unfound rickrich <~/Caches/mn.gpx  > xxx

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-oc"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/oc-newest
UPDATE_FILE=oc-newest.new
GEOMYSTERY=/dev/null

read_rc_file

#
#       Process the options
#
while getopts "D:h?-" opt
do
        case $opt in
        D)      DEBUG="$OPTARG";;
        h|\?|-) usage;;
        esac
done
shift `expr $OPTIND - 1`

#
#       Main Program
#
case "$#" in
1)	FINDER="$1"; PLACER="$1";;
*)	usage;;
esac

NUM=10000000
OCMYSTERY=$GEOMYSTERY
DISABLED=1
tr -d '\015' | oc_gpx2gpx "$FINDER" "$PLACER" 
