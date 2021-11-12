#!/bin/bash

#
#	$Id: geo-polygon.sh,v 1.26 2017/06/18 21:48:32 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Compute the centroid of a polygon

SYNOPSIS
	`basename $PROGNAME` [options] lat0 lon0 lat1 lon1 lat2 lon2 ...

DESCRIPTION
    Compute the centroid of a polygon.

    Acceptable formats for lat/lon are:

	-93.49130	DegDec (decimal degrees)
	W93.49130	DegDec (decimal degrees)
	"-93 29.478"	MinDec (decimal minutes)
	"W93 29.478"	MinDec (decimal minutes)
	-93.29.478	MinDec (decimal minutes)
	W93.29.478	MinDec (decimal minutes)
	W 93° 29.478	Cut/paste from gc.com (note it is 3 arguments)
	"-93 45 30"	DMS (degrees, minutes, seconds)

    By default, UTM is used for the calculation.  With -m, a spherical earth
    is used for the calculation.

OPTIONS
    -m		Midpoint from http://www.geomidpoint.com/
    -M		Center of gravity (midpoint) with weights
    -t		Do various centers of triangles iff you have sympy installed
    -D lvl	Debug level

EXAMPLES
    MinDec input for a 9 sided polygon:

	$ geo-polygon n42.00.126 w83.58.037 \\
		n42.00.318 w83.57.586 \\
		n42.00.120 w83.57.668 \\
		n42.00.097 w83.56.769 \\
		n41.59.988 w83.56.852 \\
		n41.59.599 w83.56.686 \\
		n41.59.987 w83.57.700 \\
		n41.59.749 w83.57.744
	n41.59.970 w83.57.331

    A Triangle:

	$ geo-polygon N42.33.767 W83.07.617 N42.33.736 W83.07.594 \\
		N42.33.736 W83.07.640
	n42.33.746 w83.07.617

    Tetrahedron using a triangle:

	$ geo-polygon -m -- -17.6829061279 175.937938962 \\
			    26.7978332041 72.5860786255 \\
			    -52.1980005058 -15.0157003564
	Normal:         s40.01.127 e96.50.457
	Antipod:        n40.01.127 w83.09.543

    A triangle using -t:

	$ geo-polygon -t N29.42.976 W82.29.858 N29.37.676 W82.24.744 \\
		N29.44.891 W82.21.642
	Center:         n29.41.849 w82.25.415
	Circumcenter:   n29.41.919 w82.25.134
	Incenter:       n29.41.795 w82.25.556
	Orthocenter:    n29.41.707 w82.25.976

    Center of gravity (midpoint) with weights:

	$ geo-polygon -M 34.663400 135.531433 8805 \\
			 35.016783 135.677433 2644 \\
		         34.586766 135.773233 1443
	Normal:         n34.43.640 e135.35.303
	Antipod:        s34.43.640 w44.24.697

SEE ALSO
    http://www.sympy.org/en/index.html

    http://www.geomidpoint.com/
EOF

	exit 1
}

#include "geo-common"

#
#	find_center npoints
#
find_center()
{
    n=$1
    awk -v n=$n -v lat="${LAT[*]}" -v lon="${LON[*]}" '
    func centroid3(p1, p2, p3) {
	lat = Lat[p1] + Lat[p2] + Lat[p3]
	lon = Lon[p1] + Lon[p2] + Lon[p3]
    }
    func area2(a, b, c) {
	return (Lat[b] - Lat[a]) * (Lon[c] - Lon[a]) - \
		(Lat[c] - Lat[a]) * (Lon[b] - Lon[a])
    }
    BEGIN {
	split(lat, Lat, " ")
	split(lon, Lon, " ")
	if (0) for (i = 1; i <= n; ++i)
	    print i, Lat[i], Lon[i]
	CG[0] = 0;
        CG[1] = 0;
        for (i = 2; i <= n-1; i++)
	{
	    centroid3(1, i, i+1);
	    A2 =  area2(1, i, i+1);
	    if (0) print A2
	    CG[0] += A2 * lat;
	    CG[1] += A2 * lon;
	    Areasum2 += A2;
	}
        CG[0] /= 3 * Areasum2;
        CG[1] /= 3 * Areasum2;
	printf "%.1f %.1f\n", CG[1], CG[0]
    }'
}

find_midpoint()
{
    n=$1
    awk -v n=$n -v lat="${LAT[*]}" -v lon="${LON[*]}" -v weight="${WEIGHT[*]}" '
    function abs(x) { return (((x < 0) ? -x : x) + 0); }
    BEGIN {
	PI=3.14159265358979323846
	split(lat, Lat, " ")
	split(lon, Lon, " ")
	split(weight, Weight, " ")
	if (0) for (i = 1; i <= n; ++i)
	    print i, Lat[i], Lon[i]
	for (i = 1; i <= n; ++i)
	{
	    Lat[i] *= PI/180.0
	    Lon[i] *= PI/180.0
	    x[i] = cos(Lat[i]) * cos(Lon[i])
	    y[i] = cos(Lat[i]) * sin(Lon[i])
	    z[i] = sin(Lat[i])
	    xt += x[i] * Weight[i]
	    yt += y[i] * Weight[i]
	    zt += z[i] * Weight[i]
	    tweight += Weight[i]
	}
	if (0) for (i = 1; i <= n; ++i)
	    print i, Lat[i], Lon[i], x[i], y[i], z[i]
	xt /= tweight
	yt /= tweight
	zt /= tweight
	if (0) print xt, yt, zt
	lat = atan2(zt, sqrt(xt * xt + yt * yt) )
	lon = atan2(yt, xt)
	lat *= 180/PI
	lon *= 180/PI
	ilat = int(lat); ilon = int(lon)
	printf "Normal: \t%s%d.%06.3f %s%d.%06.3f", \
	    lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	    lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	printf "\n"
	lat = 0.0 - lat
	lon = lon >= 0 ? -(180.0-lon) : 180.0+lon
	ilat = int(lat); ilon = int(lon)
	printf "Antipod:\t%s%d.%06.3f %s%d.%06.3f", \
	    lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	    lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	printf "\n"
    }
    '
}

find_tricenter()
{
    center=$1
    python - <<-EOF
	from sympy import *
	from sympy.geometry import Point, Triangle
	p1, p2, p3 = Point(${LON[0]}, ${LAT[0]}), \
		Point(${LON[1]}, ${LAT[1]}), Point(${LON[2]}, ${LAT[2]})
	t = Triangle(p1, p2, p3)
	print float(t.${center}.x), float(t.${center}.y)
	EOF
}

#
#       Process the options
#
DEBUG=0
MID=0
WT=0
TRI=0
while getopts "mMtD:h?" opt
do
	case $opt in
	m)	MID=1;;
	M)	MID=1; WT=1;;
	t)	TRI=1;;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

if [ "$MID" = 1 -a "$WT" = 0 ]; then
    n=0
    while [ "$#" -ge 2 ]; do
	case "$1" in
	N|S)
            if [ $# -ge 6 ]; then
                # Allow cut and paste from geocaching.com cache page
                # N 44° 58.630 W 093° 09.310
                lat=`echo "$1$2.$3" | tr -d '\260\302' `
                lat=`latlon $lat`
                lon=`echo "$4$5.$6" | tr -d '\260\302' `
                lon=`latlon $lon`
                shift 6
            else
                error "Illegal lat/lon: $*"
            fi
            ;;
	*)
            lat=`latlon $1`
            lon=`latlon $2`
            shift 2
            ;;
        esac
	LAT[n]=$lat
	LON[n]=$lon
	WEIGHT[n]=1
	((n++))
    done
    if [ $n -lt 2 ]; then
	usage
    fi
    find_midpoint $n
elif [ "$MID" = 1 -a "$WT" = 1 ]; then
    n=0
    while [ "$#" -ge 3 ]; do
	case "$1" in
	N|S)
            if [ $# -ge 6 ]; then
                # Allow cut and paste from geocaching.com cache page
                # N 44° 58.630 W 093° 09.310
                lat=`echo "$1$2.$3" | tr -d '\260\302' `
                lat=`latlon $lat`
                lon=`echo "$4$5.$6" | tr -d '\260\302' `
                lon=`latlon $lon`
                shift 6
            else
                error "Illegal lat/lon: $*"
            fi
            ;;
	*)
            lat=`latlon $1`
            lon=`latlon $2`
	    weight=$3
            shift 3
            ;;
        esac
	LAT[n]=$lat
	LON[n]=$lon
	WEIGHT[n]=$weight
	((n++))
    done
    if [ $n -lt 2 ]; then
	usage
    fi
    find_midpoint $n
else
    n=0
    while [ "$#" -ge 2 ]; do
	case "$1" in
	N|S)
            if [ $# -ge 6 ]; then
                # Allow cut and paste from geocaching.com cache page
                # N 44° 58.630 W 093° 09.310
                lat=`echo "$1$2.$3" | tr -d '\260\302' `
                lat=`latlon $lat`
                lon=`echo "$4$5.$6" | tr -d '\260\302' `
                lon=`latlon $lon`
                shift 6
            else
                error "Illegal lat/lon: $*"
            fi
            ;;
	*)
            lat=`latlon $1`
            lon=`latlon $2`
            shift 2
            ;;
        esac
	zone=$(ll2utm -- $lat $lon )
	LAT[n]=$(ll2utm -n -- $lat $lon )
	LON[n]=$(ll2utm -e -- $lat $lon )
	((n++))
    done
    if [ $n -lt 3 ]; then
	usage
    fi

    if [ $TRI = 1 -a $n = 3 ]; then
	if ! which isympy >/dev/null 2>&1; then
	    error "You need to install pythons 'isympy' (yum install isympy)"
	fi
	printf "Center:		"
	utm2ll -orickdec -- $(echo $zone | sed 's/\([A-Z]\).*/\1/') \
	    $(find_center $n)
	printf "Circumcenter:	"
	utm2ll -orickdec -- $(echo $zone | sed 's/\([A-Z]\).*/\1/') \
	    $(find_tricenter circumcenter)
	printf "Incenter:	"
	utm2ll -orickdec -- $(echo $zone | sed 's/\([A-Z]\).*/\1/') \
	    $(find_tricenter incenter)
	printf "Orthocenter:	"
	utm2ll -orickdec -- $(echo $zone | sed 's/\([A-Z]\).*/\1/') \
	    $(find_tricenter orthocenter)
    else
	utm2ll -orickdec -- $(echo $zone | sed 's/\([A-Z]\).*/\1/') \
	    $(find_center $n)
    fi
fi
