#!/bin/bash

#
#	geo-circles:
#		Compute the intersection of two circles on the earth.
#
#	Requires: bash or ksh; awk
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-circles.sh,v 1.21 2017/01/23 22:12:27 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Compute the intersection of two circles on the earth

SYNOPSIS
	`basename $PROGNAME` [options] lat1 lon1 radius1 lat2 lon2 radius2

DESCRIPTION
	Compute the intersection of two circles on the earth.

	lat/lon can be specified in DegDec or dotted MinDec format.
	radius is in meters (m) or feet (ft) or miles (mi).

	N.B. this program was inspired by Rock Johnson's "Gee" series of
	math caches.  Dyl1231, Seabiskit, and I enjoy these very much.
	Thanks RJ!

OPTIONS
	-D lvl	Debug level

EXAMPLES
	# DegDec input...

	    $ geo-circles -- 44.92592 -93.41415 307     44.92392 -93.41377 114
	    p3a = 44.923176 -93.414810      n44.55.391 w93.24.889
	    p3b = 44.923455 -93.412518      n44.55.407 w93.24.751

	# MinDec input...

	    $ geo-circles -- 44.55.435 -93.24.826 114   44.55.435 -93.24.645 150
	    p3a = 44.923455 -93.412505      n44.55.407 w93.24.750
	    p3b = 44.924445 -93.412513      n44.55.467 w93.24.751

EOF

	exit 1
}

#include "geo-common"

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
14)
	# Cut and paste from geocaching.com cache page
	# N 44° 58.630 W 093° 09.310
	LAT0=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT0=`latlon $LAT0`
	LON0=`echo "$4$5.$6" | tr -d '\260\302' `
	LON0=`latlon $LON0`
	RAD0=$7
	shift 7
	LAT1=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT1=`latlon $LAT1`
	LON1=`echo "$4$5.$6" | tr -d '\260\302' `
	LON1=`latlon $LON1`
	RAD1=$7
	shift 7
	;;
6)
	LAT0=`latlon $1`
	LON0=`latlon $2`
	RAD0=$3
	shift 3
	LAT1=`latlon $1`
	LON1=`latlon $2`
	RAD1=$3
	shift 3
	;;
*)
	usage
	;;
esac

#
#	Main Program
#
awk \
    -v LAT0="$LAT0" \
    -v LON0="$LON0" \
    -v r0="$RAD0" \
    -v LAT1="$LAT1" \
    -v LON1="$LON1" \
    -v r1="$RAD1" \
    '
function abs(x) { return (x>=0) ? x : -x }
BEGIN {
    command = sprintf("ll2utm -- %s %s", LAT0, LON0)
    command | getline;
    zone = $1
    nz = $2
    x0 = $3
    y0 = $4

    command = sprintf("ll2utm -- %s %s", LAT1, LON1)
    command | getline; x1 = $3; y1 = $4

    rise = y1 - y0
    run = x1 - x0
    d = sqrt(rise*rise + run*run)
    # printf "%s\n", d

    if (r0 ~ /ft/) 
	{ gsub("ft", "", r0); r0 *= 0.3048 }
    if (r0 ~ /mi/) 
	{ gsub("mi", "", r0); r0 *= 5280 * 0.3048 }
    if (r0 ~ /m/) 
	{ gsub("m", "", r0) }
    if (r1 ~ /ft/) 
	{ gsub("ft", "", r1); r1 *= 0.3048 }
    if (r1 ~ /mi/) 
	{ gsub("mi", "", r1); r1 *= 5280 * 0.3048 }
    if (r1 ~ /m/) 
	{ gsub("m", "", r1) }

    a = (r0*r0 - r1*r1 + d*d) / (2*d)
    # printf "%s %s\n", r0, a
    h = sqrt(r0*r0 - a*a)
    x2 = x0 + a * (x1-x0) / d
    y2 = y0 + a * (y1-y0) / d

    x3 = x2 + h * (y1-y0) / d
    y3 = y2 - h * (x1-x0) / d
    command = sprintf("utm2ll -- %s %s %s %s", zone, nx, x3, y3)
    command | getline; lat = $1; lon = $2
    printf "p3a = %f %f", lat, lon
    ilat = int(lat); ilon = int(lon)
    printf "	%s%d.%06.3f %s%d.%06.3f", \
	(lat >= 0.0) ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	(lon >= 0.0) ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
    printf "\n"

    x3 = x2 - h * (y1-y0) / d;
    y3 = y2 + h * (x1-x0) / d;
    command = sprintf("utm2ll -- %s %s %s %s", zone, nx, x3, y3)
    command | getline; lat = $1; lon = $2
    printf "p3b = %f %f", lat, lon
    ilat = int(lat); ilon = int(lon)
    printf "	%s%d.%06.3f %s%d.%06.3f", \
	(lat >= 0.0) ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	(lon >= 0.0) ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
    printf "\n"
}
'
