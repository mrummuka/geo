#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Project a waypoint

SYNOPSIS
	`basename $PROGNAME` [options] lat1 lon1 distance bearing

DESCRIPTION
	Project a waypoint.

	lat/lon can be specified in DegDec or dotted MinDec format.

	distance is in miles unless suffixed with mil, engchain, chain,
	fathom, rod, furlong, hand, link, pace, fizzy, smoot, verst,
	in, ft, yd, km, or m.

	bearing is in compass degrees unless suffixed with mil, grad, or rad,
	or n, nne, ne, ene, e, ese, se, sse, s, ssw, sw, wsw, w, wnw, nw, nnw.
	If the bearing is a negative number, then calculate in the reverse
	to:from instead of from:to.

OPTIONS
	-e	Use WGS 1984 ellipsoid calculation method [default]
	-u	Use UTM calculation method
	-s rad	Use spherical calculation method with radius = rad
	-l	Output decimal latitude only (for scripts)
	-L	Output decimal longitude only (for scripts)
	-D lvl	Debug level

EXAMPLES
	Project a waypoint 13147.2 feet at 38 degrees:

	    $ geo-project 44.47.151 -93.14.094 13147.2ft 38
	    wp = 44.814260 -93.203712       n44.48.856 w93.12.223

	Project a spherical waypoint 402.31 meters at 228.942 degrees:

	    $ geo-project -s 6378000 N42.43.919 W84.28.929 402.31m 228.942
	    wp = 42.729609 -84.485860       n42.43.777 w84.29.152

SEE ALSO
	https://en.wikipedia.org/wiki/Earth_ellipsoid

EOF

	exit 1
}

#include "geo-common"

#
#       Process the options
#
METHOD=ellipsoid
RADIUS=6378000
DEBUG=0
DOLAT=0
DOLON=0
while getopts "eulLs:D:h?" opt
do
	case $opt in
	e)	METHOD=ellipsoid;;
	u)	METHOD=utm;;
	s)	METHOD=sphere; RADIUS="$OPTARG";;
	l)	DOLAT=1;;
	L)	DOLON=1;;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$#" in
8)
	# Cut and paste from geocaching.com cache page
	# N 44ฐ 58.630 W 093ฐ 09.310
	LAT0=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT0=`latlon $LAT0`
	LON0=`echo "$4$5.$6" | tr -d '\260\302' `
	LON0=`latlon $LON0`
	DIST=$7
	BEAR=$8
	;;
6)
	LAT0=`latlon $1.$2`
	LON0=`latlon $3.$4`
	DIST=$5
	BEAR=$6
	;;
4)
	LAT0=`latlon $1`
	LON0=`latlon $2`
	DIST=$3
	BEAR=$4
	;;
*)
	usage
	;;
esac

case "$BEAR" in
n|N)		BEAR=0;;
nne|NNE)	BEAR=22.5;;
ne|NE)		BEAR=45;;
ene|ENE)	BEAR=67.5;;
e|E)		BEAR=90;;
ese|ESE)	BEAR=112.5;;
se|SE)		BEAR=135;;
sse|SSE)	BEAR=157.5;;
s|S)		BEAR=180;;
ssw|SSW)	BEAR=202.5;;
sw|SW)		BEAR=225;;
wsw|WSW)	BEAR=247.5;;
w|W)		BEAR=270;;
wnw|WNW)	BEAR=292.5;;
nw|NW)		BEAR=315;;
nnw|NNW)	BEAR=337.5;;
esac

#
#	Main Program
#
project_utm() {
    $awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v DIST="$3" \
	-v BEAR="$4" \
	-v DOLAT="$DOLAT" \
	-v DOLON="$DOLON" \
	'

    function abs(x) 	{ return (x>=0) ? x : -x }
    function asin(x)	{ return atan2(x,(1.-x^2)^0.5) }
    function acos(x)        { return atan2((1.-x^2)^0.5,x) }

    BEGIN {
	PI = 3.1415926535

	# Convert DIST to meters
	if (DIST ~ /km/)
	    { gsub("km", "", DIST); dist = DIST * 1000.0 }
	else if (DIST ~ /mil/)
	    { gsub("mil", "", DIST); dist = DIST / 39370.078740158 }
	else if (DIST ~ /engchain/)
	    { gsub("engchain", "", DIST); dist = DIST * 100.0 * 0.3048 }
	else if (DIST ~ /chain/)
	    { gsub("chain", "", DIST); dist = DIST * 66.0 * 0.3048 }
	else if (DIST ~ /fathom/)
	    { gsub("fathom", "", DIST); dist = DIST * 6.0 * 0.3048 }
	else if (DIST ~ /rod/)
	    { gsub("rod", "", DIST); dist = DIST * 16.5 * 0.3048 }
	else if (DIST ~ /furlong/)
	    { gsub("furlong", "", DIST); dist = DIST * 40 * 16.5 * 0.3048 }
	else if (DIST ~ /hand/)
	    { gsub("hand", "", DIST); dist = DIST * (5.0/12.0) * 0.3048 }
	else if (DIST ~ /link/)
	    { gsub("link", "", DIST); dist = DIST * (7.92/12.0) * 0.3048 }
	else if (DIST ~ /pace/)
	    { gsub("pace", "", DIST); dist = DIST * (30.0/12.0) * 0.3048 }
	else if (DIST ~ /fizzy/)
	    { gsub("fizzy", "", DIST); dist = DIST * 3.14159 * 1000.0 }
	else if (DIST ~ /in/)
	    { gsub("in", "", DIST); dist = DIST * (1.0/12.0) * 0.3048 }
	else if (DIST ~ /smoot/)
	    { gsub("in", "", DIST); dist = DIST * (67.0/12.0) * 0.3048 }
	else if (DIST ~ /verst/)
	    { gsub("verst", "", DIST); dist = DIST * 3500 * 0.3048 }
	else if (DIST ~ /ft/)
	    { gsub("ft", "", DIST); dist = DIST * 0.3048 }
	else if (DIST ~ /yd/)
	    { gsub("yd", "", DIST); dist = DIST * 3 * 0.3048 }
	else if (DIST ~ /mi/)
	    { gsub("mi", "", DIST); dist = DIST * 1609.344 }
	else if (DIST ~ /m/)
	    { gsub("m", "", DIST); dist = DIST * 1.0 }
	else
	    { dist = DIST * 1609.344 }

	if (BEAR ~ /mil/)
	    { gsub("mil", "", BEAR); BEAR /= 17.777777777778 }
	else if (BEAR ~ /grad/)
	    { gsub("grad", "", BEAR); BEAR /=  1.1111111111111 }
	else if (BEAR ~ /rad/)
	    { gsub("rad", "", BEAR); BEAR *= 57.295779513 }
	if (BEAR < 0) (BEAR = -BEAR + 180) % 360
	BEAR = ((360-BEAR) + 90) % 360
	bear = BEAR * (PI/180.0)

	command = sprintf("ll2utm -- %s %s", LAT0, LON0)
	command | getline;
	zone = $1
	nz = $2
	x0 = $3
	y0 = $4

	rise = dist * sin(bear)
	run = dist * cos(bear)
	# print rise, run

	x1 = x0 + run
	y1 = y0 + rise
	command = sprintf("utm2ll -- %s %s %s %s", zone, nx, x1, y1)
	command | getline; lat = $1; lon = $2
	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("	");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "wp = %f %f", lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "    %s%02d.%06.3f %s%02d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}
    }
    '
}

project_gazza() {
    $awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v DIST="$3" \
	-v BEAR="$4" \
	-v DOLAT="$DOLAT" \
	-v DOLON="$DOLON" \
	'

    function abs(x) 	{ return (x>=0) ? x : -x }
    function asin(x)	{ return atan2(x,(1.-x^2)^0.5) }
    function acos(x)        { return atan2((1.-x^2)^0.5,x) }
    function tan(x)         { return sin(x)/cos(x) }
    function atan(x)        { return atan2(x, 1.0) }
    function pow(a, b)      { return a ^ b }

    BEGIN {
	M_PI = 3.14159265358979323846
	M_PI_2 = M_PI / 2
	a = 6378388.0			# semi-major axis
	f = 1 / 297.0			# flattening

	# https://en.wikipedia.org/wiki/Earth_ellipsoid
	a = 6378137.0			# semi-major axis, WGS-84
	f = 1 / 298.257223563		# flattening, WGS-84

	b = a * (1 - f)			# semi-minor axis
	e2 = (a * a - b * b)/(a * a)	# eccentricity squared
	e = sqrt(e2)			# eccentricity
	ei2 = (a * a - b * b)/(b * b)	# second eccentricity squared
	ei = sqrt(ei2)			# second eccentricity

	lat0 = LAT0*M_PI/180.0	#radians
	lon0 = LON0*M_PI/180.0	#radians
	if (BEAR ~ /mil/)
	    { gsub("mil", "", BEAR); BEAR /= 17.777777777778 }
	else if (BEAR ~ /grad/)
	    { gsub("grad", "", BEAR); BEAR /=  1.1111111111111 }
	else if (BEAR ~ /rad/)
	    { gsub("rad", "", BEAR); BEAR *= 57.295779513 }
	if (BEAR < 0) (BEAR = -BEAR + 180) % 360
	x12 = BEAR*M_PI/180.0	#radians

	# Convert DIST to meters
	if (DIST ~ /km/)
	    { gsub("km", "", DIST); s = DIST * 1000.0 }
	else if (DIST ~ /mil/)
	    { gsub("mil", "", DIST); s = DIST / 39370.078740158 }
	else if (DIST ~ /engchain/)
	    { gsub("engchain", "", DIST); s = DIST * 100.0 * 0.3048 }
	else if (DIST ~ /chain/)
	    { gsub("chain", "", DIST); s = DIST * 66.0 * 0.3048 }
	else if (DIST ~ /fathom/)
	    { gsub("fathom", "", DIST); s = DIST * 6.0 * 0.3048 }
	else if (DIST ~ /rod/)
	    { gsub("rod", "", DIST); s = DIST * 16.5 * 0.3048 }
	else if (DIST ~ /furlong/)
	    { gsub("furlong", "", DIST); s = DIST * 40 * 16.5 * 0.3048 }
	else if (DIST ~ /hand/)
	    { gsub("hand", "", DIST); s = DIST * (5.0/12.0) * 0.3048 }
	else if (DIST ~ /link/)
	    { gsub("link", "", DIST); s = DIST * (7.92/12.0) * 0.3048 }
	else if (DIST ~ /pace/)
	    { gsub("pace", "", DIST); s = DIST * (30.0/12.0) * 0.3048 }
	else if (DIST ~ /fizzy/)
	    { gsub("fizzy", "", DIST); s = DIST * 3.14159 * 1000.0 }
	else if (DIST ~ /in/)
	    { gsub("in", "", DIST); s = DIST * (1.0/12.0) * 0.3048 }
	else if (DIST ~ /smoot/)
	    { gsub("in", "", DIST); s = DIST * (67.0/12.0) * 0.3048 }
	else if (DIST ~ /verst/)
	    { gsub("verst", "", DIST); s = DIST * 3500 * 0.3048 }
	else if (DIST ~ /ft/)
	    { gsub("ft", "", DIST); s = DIST * 0.3048 }
	else if (DIST ~ /yd/)
	    { gsub("yd", "", DIST); s = DIST * 3 * 0.3048 }
	else if (DIST ~ /mi/)
	    { gsub("mi", "", DIST); s = DIST * 1609.344 }
	else if (DIST ~ /m/)
	    { gsub("m", "", DIST); s = DIST * 1.0 }
	else
	    { s = DIST * 1609.344 }

	if (abs(s) > 10019148.059)
	{
	    print "Distance too great, use a great circle calculator instead"
	    exit(1)
	}

	tanB1 = tan(lat0) * (1 - f);
	B1 = atan(tanB1);
	cosB0 = cos(B1) * sin(x12);
	B0 = acos(cosB0);
	g = cos(B1) * cos(x12);
	m = (1 + (ei2 / 2) * sin(B1) * sin(B1)) * (1 - cos(B0) * cos(B0));
	phis = s / b;
	a1 = (1 + (ei2 / 2) * sin(B1) * sin(B1)) \
	    * (sin(B1) * sin(B1) * cos(phis) + g * sin(B1) * sin(phis));

	term1 = a1 * (-1 * (ei2 / 2) * sin(phis));
	term2 = m * (-1 * (ei2 / 4) * phis + (ei2 / 4) * sin(phis) * cos(phis));
	term3 = a1 * a1 * ((5 * ei2 * ei2 / 8) * sin(phis) * cos(phis));
	term4 = m * m * ( \
		( 11 * ei2 * ei2 / 64) * phis - (13 * ei2 * ei2 / 64) * sin(phis) \
		* cos(phis) - (ei2 * ei2 / 8) * phis * cos(phis) * cos(phis) \
		+ (5 * ei2 * ei2 / 32) * sin(phis) * pow(cos(phis), 3) \
		);
	term5 = a1 * m * ( \
		(3 * ei2 * ei2 / 8) * sin(phis) + (ei2 * ei2 /4) * phis \
		* cos(phis) - (5 * ei2 * ei2 / 8) * sin(phis) * cos(phis) \
		* cos(phis) \
		);
	phi0 = phis + term1 + term2 + term3 + term4 + term5;

	denom = sin(phi0) * sin(x12)
	if (denom == 0)
	    cotlamda = 9999999999999
	else
	    cotlamda = (cos(B1) * cos(phi0) - sin(B1) * sin(phi0) * cos(x12)) \
		    / denom
	lamda = atan(1 / cotlamda);

	term1 = -1 * f * phis;
	term2 = a1 * ((3 * f * f / 2) * sin(phis));
	term3 = m * ((3 * f * f / 4) * phis \
		    - (3 * f * f / 4) * sin(phis) * cos(phis));
	w = (term1 + term2 + term3) * cos(B0) + lamda;

	lon = lon0 + w
	
	sinB2 = sin(B1) * cos(phi0) + g * sin(phi0);
	cosB2 = sqrt((cos(B0) * cos(B0)) + \
	    pow((g * cos(phi0) - sin(B1) * sin(phi0)), 2));
	tanB2 = sinB2 / cosB2;
	tanlat2 = tanB2 / (1 - f);
	lat = atan(tanlat2);

	lon = lon*180.0 / M_PI
	lat = lat*180.0 / M_PI

	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("	");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "wp = %f %f", lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "	%s%02d.%06.3f %s%02d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}
    }
    '
}

project_sphere() {
    $awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v DIST="$3" \
	-v BEAR="$4" \
	-v RADIUS="$RADIUS" \
	-v DOLAT="$DOLAT" \
	-v DOLON="$DOLON" \
	'

    function abs(x) 	{ return (x>=0) ? x : -x }
    function asin(x)	{ return atan2(x,(1.-x^2)^0.5) }
    function acos(x)        { return atan2((1.-x^2)^0.5,x) }
    function tan(x)         { return sin(x)/cos(x) }
    function atan(x)        { return atan2(x, 1.0) }
    function pow(a, b)      { return a ^ b }

    BEGIN {
	M_PI = 3.14159265358979323846
	M_PI_2 = M_PI / 2

	lat1 = LAT0*M_PI/180.0	#radians
	lon1 = LON0*M_PI/180.0	#radians
	if (BEAR ~ /mil/)
	    { gsub("mil", "", BEAR); BEAR /= 17.777777777778 }
	else if (BEAR ~ /grad/)
	    { gsub("grad", "", BEAR); BEAR /=  1.1111111111111 }
	else if (BEAR ~ /rad/)
	    { gsub("rad", "", BEAR); BEAR *= 57.295779513 }
	if (BEAR < 0) (BEAR = -BEAR + 180) % 360
	brng = BEAR*M_PI/180.0	#radians

	# Convert DIST to meters
	if (DIST ~ /km/)
	    { gsub("km", "", DIST); s = DIST * 1000.0 }
	else if (DIST ~ /mil/)
	    { gsub("mil", "", DIST); s = DIST / 39370.078740158 }
	else if (DIST ~ /engchain/)
	    { gsub("engchain", "", DIST); s = DIST * 100.0 * 0.3048 }
	else if (DIST ~ /chain/)
	    { gsub("chain", "", DIST); s = DIST * 66.0 * 0.3048 }
	else if (DIST ~ /fathom/)
	    { gsub("fathom", "", DIST); s = DIST * 6.0 * 0.3048 }
	else if (DIST ~ /rod/)
	    { gsub("rod", "", DIST); s = DIST * 16.5 * 0.3048 }
	else if (DIST ~ /furlong/)
	    { gsub("furlong", "", DIST); s = DIST * 40 * 16.5 * 0.3048 }
	else if (DIST ~ /hand/)
	    { gsub("hand", "", DIST); s = DIST * (5.0/12.0) * 0.3048 }
	else if (DIST ~ /link/)
	    { gsub("link", "", DIST); s = DIST * (7.92/12.0) * 0.3048 }
	else if (DIST ~ /pace/)
	    { gsub("pace", "", DIST); s = DIST * (30.0/12.0) * 0.3048 }
	else if (DIST ~ /fizzy/)
	    { gsub("fizzy", "", DIST); s = DIST * 3.14159 * 1000.0 }
	else if (DIST ~ /in/)
	    { gsub("in", "", DIST); s = DIST * (1.0/12.0) * 0.3048 }
	else if (DIST ~ /smoot/)
	    { gsub("in", "", DIST); s = DIST * (67.0/12.0) * 0.3048 }
	else if (DIST ~ /verst/)
	    { gsub("verst", "", DIST); s = DIST * 3500 * 0.3048 }
	else if (DIST ~ /ft/)
	    { gsub("ft", "", DIST); s = DIST * 0.3048 }
	else if (DIST ~ /yd/)
	    { gsub("yd", "", DIST); s = DIST * 3 * 0.3048 }
	else if (DIST ~ /mi/)
	    { gsub("mi", "", DIST); s = DIST * 1609.344 }
	else if (DIST ~ /m/)
	    { gsub("m", "", DIST); s = DIST * 1.0 }
	else
	    { s = DIST * 1609.344 }

	if (abs(s) > 10019148.059)
	{
	    print "Distance too great, use a great circle calculator instead"
	    exit(1)
	}

	dist = s / RADIUS	# convert dist to angular distance in radians
	lat2 = asin( sin(lat1)*cos(dist) + \
		    cos(lat1)*sin(dist)*cos(brng) )
	lon2 = lon1 + atan2(sin(brng)*sin(dist)*cos(lat1), \
			   cos(dist)-sin(lat1)*sin(lat2))
	lon2 = (lon2+3*M_PI) % (2*M_PI) - M_PI;  # normalise to -180..+180ยบ

	lat = lat2
	lon = lon2
	lon = lon*180.0 / M_PI
	lat = lat*180.0 / M_PI

	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("	");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "wp = %f %f", lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "	%s%02d.%06.3f %s%02d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}
    }
    '
}

case "$METHOD" in
utm)
    project_utm $LAT0 $LON0 $DIST $BEAR
    ;;
sphere)
    project_sphere $LAT0 $LON0 $DIST $BEAR
    ;;
*)
    project_gazza $LAT0 $LON0 $DIST $BEAR
    ;;
esac
