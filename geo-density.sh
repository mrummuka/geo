#!/bin/bash

#
#	geo-nearest: Fetch list of nearest geocaches.
#
#	Requires: curl; gpsbabel; bash or ksh;
#		  mysql (if using the gpsdrive.sql output option)
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-density.sh,v 1.14 2013/02/18 21:41:06 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Compute the cache density of a circular area

SYNOPSIS
	`basename $PROGNAME` [options]
	`basename $PROGNAME` [options] latitude longitude
	`basename $PROGNAME` [options] zipcode

DESCRIPTION
	Compute the cache density of a circular area.

OPTIONS
        -c              Remove cookie file when done
	-q		Qualifier: unknown
        -r radius       Radius in miles for computing the density [$RADIUS]

        -D lvl          Debug level [0]
        -U              Retrieve latest version of this script

    Defaults can also be set with variables in file $HOME/.georc:

        LAT=latitude;       LON=logitude;

SEE ALSO
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/geo-density
UPDATE_FILE=geo-density.new

read_rc_file

#
#       Process the options
#
RADIUS=4

gc_getopts "$@"
shift $?

LOC="$*"
if [ "" = "$LOC" ]; then
    LOC="$(degdec2mindec $LAT) $(degdec2mindec $LON)"
fi

#
#	Main Program
#
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

HTMLPAGE=$TMP.page
ZIPRESP=$TMP.zip

CRUFT="$CRUFT $HTMLPAGE"
CRUFT="$CRUFT $ZIPRESP"
if [ $NOCOOKIES = 1 ]; then
    CRUFT="$CRUFT $COOKIE_FILE"
fi

case "$#" in
6)
	# Cut and paste from geocaching.com cache page
	# N 44° 58.630 W 093° 09.310
	LAT=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT=`latlon $LAT`
	LON=`echo "$4$5.$6" | tr -d '\260\302' `
	LON=`latlon $LON`
	SEARCH="?origin_lat=$LAT&origin_long=$LON"
	;;
2)
	LAT=`latlon $1`
	LON=`latlon $2`
	SEARCH="?origin_lat=$LAT&origin_long=$LON"
	;;
1)
	case "$1" in
	*[0-9]*) ZIP=$1 ;;
	*) error "'$1' isn't something I understand how to search for" ;;
	esac

	# Lookup the zip code from Google Maps
	URL="http://maps.googleapis.com/maps/api/geocode/xml?address=$ZIP"
	URL="$URL&sensor=false"
	curl $CURL_OPTS -L -s -A "$UA" "$URL" \
	    | sed -e '1,/<location>/d' -e '/<.location>/,$d' > $ZIPRESP
	#cat $ZIPRESP
	LAT=` grep lat $ZIPRESP | sed -e 's/.*<lat>//' -e 's/<.*//' `
	LON=` grep lng $ZIPRESP | sed -e 's/.*<lng>//' -e 's/<.*//' `
	SEARCH="?origin_lat=$LAT&origin_long=$LON"
	;;
0)
	SEARCH="?origin_lat=$LAT&origin_long=$LON"
	;;
*)
	usage
	;;
esac

#
# Fetch the page of closest caches and scrape the cache ID's
#
URL="$GEO/seek/nearest.aspx"
URL="$URL$SEARCH&dist=$RADIUS"
#
case "$POCKETQUERY" in
unknown)
    URL="$URL&cFilter=40861821-1835-4e11-b666-8d41064d03fe-parent"
    URL="$URL&children=y"
    ;;
esac
dbgcmd curl $CURL_OPTS -L -s -A "$UA" "$URL" > $HTMLPAGE

ncaches=$(sed -n -e '/Distances measured/,$d' \
	    -e "s/^.*<span>Total Records: <b>\([0-9]*\)<.b> -.*/\1/p" \
		< $HTMLPAGE)
debug 2 "ncaches = $ncaches"
if [ "" != "$ncaches" ]; then
    density=$(dc -e "3k $ncaches 50 /p")
    printf "Cache Density is %.3f caches/sq.mile for $LOC\n" $density
else
    echo "Location unknown: $LOC"
fi
