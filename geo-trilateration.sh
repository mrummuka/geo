#!/bin/bash

#
#	geo-trilateration:
#		Compute the intersection of three circles on the earth.
#
#	Requires: bash or ksh; awk
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-trilateration.sh,v 1.18 2018/03/15 16:51:12 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Compute the intersection of three circles

SYNOPSIS
	`basename $PROGNAME` [options] lat0 lon0 rad0 lat1 lon1 rad1 lat2 lon2 rad2

DESCRIPTION
	Compute the intersection of three circles on the earth.

	lat/lon can be specified in DegDec or dotted MinDec format.
	radius is in meters (m), kilometers (km), feet (ft) or miles (mi).

	N.B. this program was inspired by Rock Johnson's "Gee" series of
	math caches.  Dyl1231, Seabiskit, and I enjoy these very much.
	Thanks RJ!

OPTIONS
	-f	Pretend that the world is flat
		and 1 degree latitude == 1 degree longitude
	-D lvl	Debug level

EXAMPLES
	# DegDec input...

	    $ geo-trilateration 44.92342 -93.41253 382 \\
		    44.92335 -93.41165 398 \\
		    44.55.502   -93.24.795 205
	    p3a = 44.920119 -93.413749      n44.55.207 w93.24.825
	    p3b = 44.926875 -93.412695      n44.55.613 w93.24.762   <--
	    p3a = 44.926874 -93.412796      n44.55.612 w93.24.768   <--
	    p3b = 44.926326 -93.415098      n44.55.580 w93.24.906
	    p3a = 44.926875 -93.412745      n44.55.613 w93.24.765   <--
	    p3b = 44.925423 -93.415801      n44.55.525 w93.24.948

	# MinDec input...

	    $ geo-trilateration 44.53.200 w93.36.000 370m \\
		    44.53.000 w93.36.200 262m \\
		    44.53.200 w93.36.200 453m
	    p3a = 44.885602 -93.604417      n44.53.136 w93.36.265
	    p3b = 44.883374 -93.600012      n44.53.002 w93.36.001   <--
	    p3a = 44.890036 -93.600031      n44.53.402 w93.36.002
	    p3b = 44.883374 -93.600025      n44.53.002 w93.36.002   <--
	    p3a = 44.883374 -93.600012      n44.53.002 w93.36.001   <--
	    p3b = 44.883339 -93.606647      n44.53.000 w93.36.399

	# Flat World...

	    $ geo-trilateration -f \\
		    N 45 04.033 W 093 03.667 0.015611742375526 \\
		    N 45 03.491 W 093 04.787 0.00836557828246395 \\
		    N 45 04.655 W 093 04.569 0.0116429978957274
	    p3a = 45.065950 -93.076676      n45.03.957 w93.04.601   <--
	    p3b = 45.055799 -93.071764      n45.03.348 w93.04.306
	    p3a = 45.082210 -93.065466      n45.04.933 w93.03.928
	    p3b = 45.065952 -93.076676      n45.03.957 w93.04.601   <--
	    p3a = 45.065952 -93.076681      n45.03.957 w93.04.601   <--
	    p3b = 45.066548 -93.079864      n45.03.993 w93.04.792

SEE ALSO
	http://en.wikipedia.org/wiki/Trilateration

EOF

	exit 1
}

#include "geo-common"

#
#       Process the options
#
DEBUG=0
FLAT=0
while getopts "fD:h?" opt
do
	case $opt in
	f)	FLAT=1;;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$#" in
21)
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
	LAT2=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT2=`latlon $LAT2`
	LON2=`echo "$4$5.$6" | tr -d '\260\302' `
	LON2=`latlon $LON2`
	RAD2=$7
	shift 7
	;;
9)
	LAT0=`latlon $1`
	LON0=`latlon $2`
	RAD0=$3
	shift 3
	LAT1=`latlon $1`
	LON1=`latlon $2`
	RAD1=$3
	shift 3
	LAT2=`latlon $1`
	LON2=`latlon $2`
	RAD2=$3
	shift 3
	;;
*)
	usage
	;;
esac

#
#	Main Program
#
geo_circles() {
    awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v r0="$3" \
	-v LAT1="$4" \
	-v LON1="$5" \
	-v r1="$6" \
	-v FLAT="$FLAT" \
	'
    function abs(x) { return (x>=0) ? x : -x }
    BEGIN {
	if (FLAT)
	{
	    x0 = LON0
	    y0 = LAT0
	    x1 = LON1
	    y1 = LAT1
	}
	else
	{
	    command = sprintf("ll2utm -- %s %s", LAT0, LON0)
	    command | getline;
	    zone = $1
	    nz = $2
	    x0 = $3
	    y0 = $4

	    command = sprintf("ll2utm -- %s %s", LAT1, LON1)
	    command | getline;
	    x1 = $3; y1 = $4
	}

	rise = y1 - y0
	run = x1 - x0
	d = sqrt(rise*rise + run*run)
	# printf "%s\n", d

	if (r0 ~ /ft/) 
	    { gsub("ft", "", r0); r0 *= 0.3048 }
	if (r0 ~ /mi/) 
	    { gsub("mi", "", r0); r0 *= 5280 * 0.3048 }
	if (r0 ~ /km/) 
	    { gsub("km", "", r0); r0 *= 1000 }
	if (r0 ~ /m/) 
	    { gsub("m", "", r0) }
	if (r1 ~ /ft/) 
	    { gsub("ft", "", r1); r1 *= 0.3048 }
	if (r1 ~ /mi/) 
	    { gsub("mi", "", r1); r1 *= 5280 * 0.3048 }
	if (r1 ~ /km/) 
	    { gsub("km", "", r1); r1 *= 1000 }
	if (r1 ~ /m/) 
	    { gsub("m", "", r1) }

	a = (r0*r0 - r1*r1 + d*d) / (2*d)
	# printf "%s %s\n", r0, a
	h = sqrt(r0*r0 - a*a)
	# print r0*r0 - a*a
	x2 = x0 + a * (x1-x0) / d
	y2 = y0 + a * (y1-y0) / d

	x3 = x2 + h * (y1-y0) / d
	y3 = y2 - h * (x1-x0) / d
	if (FLAT)
	{
	    lat = y3
	    lon = x3
	}
	else
	{
	    command = sprintf("utm2ll -- %s %s %s %s", zone, nx, x3, y3)
	    command | getline; lat = $1; lon = $2
	}
	printf "p3a = %f %f", lat, lon
	ilat = int(lat); ilon = int(lon)
	printf "    %s%02d.%06.3f %s%02d.%06.3f", \
	    lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	    lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	printf "\n"

	x3 = x2 - h * (y1-y0) / d;
	y3 = y2 + h * (x1-x0) / d;
	if (FLAT)
	{
	    lat = y3
	    lon = x3
	}
	else
	{
	    command = sprintf("utm2ll -- %s %s %s %s", zone, nx, x3, y3)
	    command | getline; lat = $1; lon = $2
	}
	printf "p3b = %f %f", lat, lon
	ilat = int(lat); ilon = int(lon)
	printf "    %s%02d.%06.3f %s%02d.%06.3f", \
	    lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	    lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	printf "\n"
    }
    '
}
geo_circles $LAT0 $LON0 $RAD0 $LAT1 $LON1 $RAD1
geo_circles $LAT0 $LON0 $RAD0 $LAT2 $LON2 $RAD2
geo_circles $LAT1 $LON1 $RAD1 $LAT2 $LON2 $RAD2
