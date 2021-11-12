#!/bin/bash

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Display a map of a point using aerial photos

SYNOPSIS
    `basename $PROGNAME` [options] lat lon

DESCRIPTION
    Display a map of a point using Bing, Google, AOL, or MapQuest
    aerial photos and Firefox.

OPTIONS
    -b		Batch mode on stdin.
    -a source	source: mapquest, bing, google, aol [$SOURCE]
    -n number	Google maps number [$NUM]
    -s		Google Streetview
    -z zoom	Zoom level (max, 1-19) [$ZOOM]
    -D lvl	Debug level

EXAMPLES
    $ geo-firefox 45.04.337 w93.45.414 #A

    $ geo-firefox -z 13 45.03.274 w93.38.288 #B

    $ geo-firefox 45.00.601 w93.21.109 #C

    $ geo-firefox 44.59.668 w93.15.301 #D

    $ geo-firefox 45.035778 w93.512187

    $ geo-firefox -s N21.27.588 W157.49.934

    $ geo-firefox -b

SEE ALSO
    geo-map, http://geo.rkkda.com/

EOF

	exit 1
}

#include "geo-common"

#
#       Process the options
#
DEBUG=0
ZOOM=max
SOURCE=mapquest
SOURCE=aol
SOURCE=google
STREETVIEW=
NUM=5
while getopts "a:bn:sz:D:h?" opt
do
	case $opt in
	a)	SOURCE="$OPTARG";;
	n)	NUM="$OPTARG";;
	b)	while read a; do
		    geo-firefox -- $a
		done
		exit
		;;
	z)	ZOOM="$OPTARG";;
	s)	SOURCE=google; STREETVIEW="&layer=c";;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$#" in
6|7)	# 7 for N 44° 58.630 W 093° 09.310 no
    # Cut and paste from geocaching.com cache page
    # N 44° 58.630 W 093° 09.310
    LAT=`echo "$1$2.$3" | tr -d '\*\260\302' `
    LAT=`latlon $LAT`
    LON=`echo "$4$5.$6" | tr -d '\*\260\302' `
    LON=`latlon $LON`
    ;;
4)
    LAT=`latlon $1.$2`
    LON=`latlon $3.$4`
    ;;
2|3)	# 3 for N44.58.630 W93.09.310 no
    LAT=`latlon $1`
    LON=`latlon $2`
    ;;
1)
    # cut from google maps
    LAT=`echo "$1" | sed -e 's/,.*//'`
    LON=`echo "$1" | sed -e 's/.*,//'`
    LAT=`latlon $LAT`
    LON=`latlon $LON`
    ;;
*)
    error "Need lat/lon"
    ;;
esac

#
#	Main Program
#

dlat=`geo-coords -l -d -- $LAT $LON`
dlon=`geo-coords -L -d -- $LAT $LON`
mlat=`geo-coords -l -m -- $LAT $LON | sed 's/\./\+/' `
mlon=`geo-coords -L -m -- $LAT $LON | sed 's/\./\+/' `

doit() {
    echo "$1$2$3$4$5"
    if [ `uname` = Darwin ]; then
	open -a Firefox "$1$2$3$4$5"
    else
	# Fedora 19 has a bug, thus 2>/dev/null
	firefox "$1$2$3$4$5" 2>/dev/null
    fi
}

case "$SOURCE" in
m*)
    case "$ZOOM" in
    1|2|3|4|5|6|7|8|9)	;;
    10|11|12|13|14)	;;
    15|16|17|18|19)	ZOOM=16;;
    max)		ZOOM=16;;
    *)			error "Zoom level 1-16 or max";;
    esac
    doit \
	"http://www.mapquest.com/?q=$dlat,$dlon&zoom=$ZOOM&maptype=hyb"
	# "http://atlas.mapquest.com/maps/map.adp?zoom=$ZOOM&formtype=latlong&latlongtype=decimal&latitude=$dlat&longitude=$dlon&dtype=h"
    ;;
a*)
    case "$ZOOM" in
    1|2|3|4|5|6|7|8|9)	;;
    10|11|12|13|14)	;;
    15|16|17|18|19)	ZOOM=16;;
    max)		ZOOM=16;;
    *)			error "Zoom level 1-16 or max";;
    esac
    doit \
	"http://mqprint-vd03.evip.aol.com/staticmap/v3/getmap" \
	"?key=YOUR_KEY_HERE" \
	"&center=$dlat,$dlon&zoom=$ZOOM" \
	"&size=800,800&type=hyb&imagetype=png&pois=mcenter,$dlat,$dlon"
    ;;
g*)
    case "$ZOOM" in
    1|2|3|4|5|6|7|8|9)	;;
    10|11|12|13|14)	;;
    15|16|17|18|19)	;;
    max)		ZOOM=19;;
    *)			error "Zoom level 1-19 or max";;
    esac
    if [ "$STREETVIEW" != "" ]; then
	STREETVIEW="$STREETVIEW&cbp=12,0,0,0,0"
	STREETVIEW="$STREETVIEW&cbll=$dlat,$dlon"
    fi
    case "$NUM" in
    1)
	# old style, gone as of ~ 4/25/15
	doit \
	"http://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&q=$mlat+$mlon&ie=UTF8&t=h&ll=$dlat,$dlon&z=$ZOOM$STREETVIEW&output=classic"
	;;
    2)
	# new style, maybe it will last? dead 5/28/15
	doit \
	"http://www.google.com/lochp?f=q&source=s_q&hl=en&geocode=&q=$mlat+$mlon&ie=UTF8&t=h&ll=$dlat,$dlon&z=$ZOOM$STREETVIEW&output=classic"
	;;
    3)
	# new style, note classic w/o the last c!
	doit \
	"http://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&q=$mlat+$mlon&ie=UTF8&t=h&ll=$dlat,$dlon&z=$ZOOM$STREETVIEW&output=classi"
	;;
    4)
	# http://gokml.net/maps
	doit \
	"http://gokml.net/maps?f=q&source=s_q&hl=en&geocode=&q=$mlat+$mlon&ie=UTF8&t=h&ll=$dlat,$dlon&z=$ZOOM$STREETVIEW&output=classi"
	;;
    5)
	# http://www.rkkda.com/tmp/newmap.html
	doit \
	"http://www.rkkda.com/tmp/newmap.html?f=q&source=s_q&hl=en&geocode=&q=http $mlat+$mlon&ie=UTF8&t=h&ll=$dlat,$dlon&z=$ZOOM$STREETVIEW&output=classi"
	;;
    6)
	# new style, https://www.google.com/maps/mms, but no pins at all!
	doit \
	"http://maps.google.com/maps/mms?f=q&source=s_q&hl=en&geocode=&q=$mlat+$mlon&ie=UTF8&t=h&ll=$dlat,$dlon&z=$ZOOM$STREETVIEW&output=classi"
    esac
    ;;
b*)
    case "$ZOOM" in
    1|2|3|4|5|6|7|8|9)	;;
    10|11|12|13|14)	;;
    15|16|17|18|19)	;;
    max)	ZOOM=19;;
    *)			error "Zoom level 1-19 or max";;
    esac
    doit \
	"http://www.bing.com/maps/default.aspx?v=2&FORM=LMLTCP&cp=$dlat~$dlon&style=h&lvl=$ZOOM&tilt=n&dir=0&alt=-1000&phx=0&phy=0&phscl=1&encType=1&rtp=pos.${dlat}_${dlon}_AAA"
    ;;
esac
