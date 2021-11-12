#!/bin/sh

PROGNAME="$0"

usage() {
    cat <<EOF
NAME
    `basename $PROGNAME` - Compute the intersection of two lines

SYNOPSIS
    `basename $PROGNAME` [options] point1 point2 point3 point4

    `basename $PROGNAME` [options] point1 bearing1 point2 bearing2

DESCRIPTION
    Compute the intersection of two lines.  You can use two forms.
    Line segment point1-point2 and line segment point3-point4 computes
    it by "X marks the spot". Line segment point1 bearing1 and line
    segment point2 bearing2 computes it by heading.

OPTIONS
    -b		Bearing
    -p		Planar.  Disregard curvature of the surface of the earth.
    -D lvl	Debug level

EXAMPLE
    Compute the intersection by lines:

	$ geo-intersect \\
	      45.04.337 w93.45.414 45.03.274 w93.38.288 \\
	      45.00.601 w93.21.109 44.59.668 w93.15.301
	N45.02.199 W93.31.139

    Compute the intersection by bearings:

	$ geo-intersect 45 -93 315 45 -94 45
	n45.21.018 w93.30.000

	$ geo-intersect N 45 27.671 W 75 37.390 232 N 45 27.915 W 75 38.192 134
	n45.27.537 w75.37.634

EOF

    exit 1
}

#include "geo-common"

#
#       Process the options
#
PLANAR=0
DEBUG=0
BEAR=0
while getopts "bpD:h?" opt
do
    case $opt in
    b)	BEAR=1;;
    p)	PLANAR=1;;
    D)	DEBUG="$OPTARG";;
    h|\?)	usage;;
    esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
case "$#" in
24)
    # Cut and paste from geocaching.com cache page
    # N 44° 58.630 W 093° 09.310
    LAT1=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT1=`latlon $LAT1`
    LON1=`echo "$4$5.$6" | tr -d '\260\302' `
    LON1=`latlon $LON1`
    shift 6
    LAT2=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT2=`latlon $LAT2`
    LON2=`echo "$4$5.$6" | tr -d '\260\302' `
    LON2=`latlon $LON2`
    shift 6
    LAT3=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT3=`latlon $LAT3`
    LON3=`echo "$4$5.$6" | tr -d '\260\302' `
    LON3=`latlon $LON3`
    shift 6
    LAT4=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT4=`latlon $LAT4`
    LON4=`echo "$4$5.$6" | tr -d '\260\302' `
    LON4=`latlon $LON4`
    shift 6
    ;;
14)
    # Cut and paste from geocaching.com cache page
    # N 44° 58.630 W 093° 09.310
    BEAR=1
    LAT1=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT1=`latlon $LAT1`
    LON1=`echo "$4$5.$6" | tr -d '\260\302' `
    LON1=`latlon $LON1`
    shift 6
    BEAR1=$1
    shift 1
    LAT2=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT2=`latlon $LAT2`
    LON2=`echo "$4$5.$6" | tr -d '\260\302' `
    LON2=`latlon $LON2`
    shift 6
    BEAR2=$1
    shift 1
    ;;
8)
    LAT1=`latlon $1`
    LON1=`latlon $2`
    shift 2
    LAT2=`latlon $1`
    LON2=`latlon $2`
    shift 2
    LAT3=`latlon $1`
    LON3=`latlon $2`
    shift 2
    LAT4=`latlon $1`
    LON4=`latlon $2`
    shift 2
    ;;
6)
    BEAR=1
    LAT1=`latlon $1`
    LON1=`latlon $2`
    shift 2
    BEAR1=$1
    shift 1
    LAT2=`latlon $1`
    LON2=`latlon $2`
    shift 2
    BEAR2=$1
    shift 1
    ;;
*)
    usage
    ;;
esac

if [ $BEAR = 1 ]; then
    awk \
	-v LAT1=$LAT1 \
	-v LON1=$LON1 \
	-v BEAR1=$BEAR1 \
	-v LAT2=$LAT2 \
	-v LON2=$LON2 \
	-v BEAR2=$BEAR2 \
    '
    function deg2rad(angle)
    {
	return angle * .017453292519943295	# (angle / 180) * PI;
    }
    function rad2deg(angle)
    {
	return angle * 57.29577951308232	# angle / PI * 180
    }
    function abs(x)	{ return (x>=0) ? x : -x }
    function asin(x)	{ return atan2(x,(1.-x^2)^0.5) }
    function acos(x)	{ return atan2((1.-x^2)^0.5,x) }
    function fmod(x, y)	{ return (x % y) }
    BEGIN { 
	PI = 3.14159265358979323846
	lat1 = deg2rad(LAT1)
	lon1 = deg2rad(LON1)
	bear13 = deg2rad(BEAR1)
	lat2 = deg2rad(LAT2)
	lon2 = deg2rad(LON2)
	bear23 = deg2rad(BEAR2)
	
	dLat = lat2 - lat1;
	dLon = lon2 - lon1;
	dist12 = 2*asin( sqrt( sin(dLat/2)*sin(dLat/2) + \
	    cos(lat1)*cos(lat2)*sin(dLon/2)*sin(dLon/2) ) )
	if (dist12 == 0)
	{
	    print "no distance!"
	    exit
	}
  
	# initial/final bearings between points
	bearA = acos( ( sin(lat2) - sin(lat1)*cos(dist12) ) / \
		    ( sin(dist12)*cos(lat1) ) );
	# if (isNaN(bearA)) bearA = 0;  # protect against rounding
	bearB = acos( ( sin(lat1) - sin(lat2)*cos(dist12) ) / \
		    ( sin(dist12)*cos(lat2) ) );
  
	if (sin(lon2-lon1) > 0)
	{
	    bear12 = bearA;
	    bear21 = 2*PI - bearB;
	}
	else
	{
	    bear12 = 2*PI - bearA;
	    bear21 = bearB;
	}
  
	alpha1 = (bear13 - bear12 + PI) % (2*PI) - PI;  # angle 2-1-3
	alpha2 = (bear21 - bear23 + PI) % (2*PI) - PI;  # angle 1-2-3
  
	if (sin(alpha1)==0 && sin(alpha2)==0)
	{
	    print "infinite intersections"
	    exit
	}
	if (sin(alpha1)*sin(alpha2) < 0)
	{
	    print "ambiguous intersection"
	    exit
	}
  
	alpha3 = acos( -cos(alpha1)*cos(alpha2) + \
                       sin(alpha1)*sin(alpha2)*cos(dist12) );
	dist13 = atan2( sin(dist12)*sin(alpha1)*sin(alpha2), \
                       cos(alpha2)+cos(alpha1)*cos(alpha3) )
	lat3 = asin( sin(lat1)*cos(dist13) + \
                    cos(lat1)*sin(dist13)*cos(bear13) );
	dLon13 = atan2( sin(bear13)*sin(dist13)*cos(lat1), \
                       cos(dist13)-sin(lat1)*sin(lat3) );
	lon3 = lon1+dLon13;
	lon3 = (lon3+3*PI) % (2*PI) - PI;  # normalise to -180..+180º
	lat = rad2deg(lat3)
	lon = rad2deg(lon3)
	ilat = int(lat); ilon = int(lon)
	printf "%s%d.%06.3f %s%d.%06.3f", \
	    lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	    lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	printf "\n"
    }
    '
    exit
fi

if [ $PLANAR = 0 ];then
    ZONE=`ll2utm -z -- $LAT1 $LON1`
    LATBAND=`ll2utm -l -- $LAT1 $LON1`
    x1=`ll2utm -e -- $LAT1 $LON1`
    y1=`ll2utm -n -- $LAT1 $LON1`
    x2=`ll2utm -e -- $LAT2 $LON2`
    y2=`ll2utm -n -- $LAT2 $LON2`
    x3=`ll2utm -e -- $LAT3 $LON3`
    y3=`ll2utm -n -- $LAT3 $LON3`
    x4=`ll2utm -e -- $LAT4 $LON4`
    y4=`ll2utm -n -- $LAT4 $LON4`
else
    x1=`geo-coords -d -L -- $LAT1 $LON1`
    y1=`geo-coords -d -l -- $LAT1 $LON1`
    x2=`geo-coords -d -L -- $LAT2 $LON2`
    y2=`geo-coords -d -l -- $LAT2 $LON2`
    x3=`geo-coords -d -L -- $LAT3 $LON3`
    y3=`geo-coords -d -l -- $LAT3 $LON3`
    x4=`geo-coords -d -L -- $LAT4 $LON4`
    y4=`geo-coords -d -l -- $LAT4 $LON4`
fi

docalc() {
    awk \
	-v x1=$x1 \
	-v y1=$y1 \
	-v x2=$x2 \
	-v y2=$y2 \
	-v x3=$x3 \
	-v y3=$y3 \
	-v x4=$x4 \
	-v y4=$y4 \
	-v p=$PLANAR \
    '
    BEGIN {
	if ( ( (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1) ) == 0)
	    exit 1
	ua = ( (x4-x3)*(y1-y3) - (y4-y3)*(x1-x3) ) / \
	    ( (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1) )
	ub = ( (x2-x1)*(y1-y3) - (y2-y1)*(x1-x3) ) / \
	    ( (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1) )

	x = x1 + ua * (x2-x1)
	y = y1 + ua * (y2-y1)
	if (p)
	    printf "%.6f %.6f\n",  y, x
	else
	    printf "%.0f %.0f\n",  x, y
    }'
}

if [ $PLANAR = 1 ]; then
    xy=`docalc`
    if [ $? != 0 ]; then
	error "Points do not intersect!"
    fi
    geo-coords -m -- $xy
else
    xy=`docalc`
    if [ $? != 0 ]; then
	error "Points do not intersect!"
    fi
    geo-coords -m -- `utm2ll $ZONE $LATBAND $xy`
fi
