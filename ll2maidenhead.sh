#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Lat/long to Maidenhead (Grid Squares)

SYNOPSIS
	`basename $PROGNAME` [options] lat lon ...

DESCRIPTION
	Lat/long to Maidenhead Locator System a.k.a. Grid Squares.

EXAMPLES
	# DegDec input...

	    $ ll2maidenhead 7.47194 47.22470
	    LJ37OL

	# MinDec input...

	    $ ll2maidenhead n45.00.000 w93.30.000
	    EN35GA

	# Copied from gc.com...

	    $ ll2maidenhead N 44° 59.989 W 093° 22.881
	    EN34HX

	# Batch ...

	    $ cat <<EOF |
	    > 40.806862       -96.681679
	    > 39.7391536      -104.9847034
	    > 33.5206608      -86.80249
	    > 39.114053       -94.6274636
	    > 32.802955       -96.769923
	    > 41.0814447      -81.5190053
	    > 46.1381676      -122.9381672
	    > 43.0730517      -89.4012302
	    > EOF
	    > while read lat lon; do
	    >     ll2maidenhead \$lat \$lon
	    > done
	    EN10PT
	    DM79MR
	    EM63OM
	    EM29QC
	    EM12OT
	    EN91FB
	    CN86MD
	    EN53HB

OPTIONS
	-D lvl	Debug level
EOF

	exit 1
}

#include "geo-common"

#
#       Report an error and exit
#
error() {
	echo "`basename $PROGNAME`: $1" >&2
	exit 1
}

debug() {
	if [ $DEBUG -ge $1 ]; then
	    echo "`basename $PROGNAME`: $2" >&2
	fi
}

#
#       Process the options
#
DEBUG=0
while getopts "D:h?" opt
do
	case $opt in
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$#" in
0)	usage ;;
esac

encode() {
awk -v LAT=$1 -v LON=$2 '
    function char(v) { return v }
    function num2str(v) { return v }
    function LLtoGRID(lat, lon)
    {
	lon_mh = lon + 180.0
	lat_mh = lat + 90.0

	digit1 = int(lon_mh/20) + 1
	char1 = char(digit1 + 64)

	digit2 = int(lat_mh/10)+1
	char2 = char(digit2+64)

	digit3 = int( (lon_mh % 20) / 2 )
	str3 = num2str(digit3)

	digit4 = int( (lat_mh % 10) / 1 )
	str4 = num2str(digit4)

	digit5 = int( (lon_mh % 2) * 60/5 ) + 1
	char5 = char(digit5+64)

	digit6 = int( (lat_mh % 1) / 1 * 60/2.5 ) + 1
	char6 = char(digit6+64)
	printf "%c%c%s%s%c%c\n", char1, char2, str3, str4, char5, char6
    }

    BEGIN {
	LLtoGRID(LAT, LON)
    }
    '
}

#
#	Main Program
#
process_latlon encode 0 $@
