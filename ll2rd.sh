#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Lat/Lon to RD (Dutch)

SYNOPSIS
	`basename $PROGNAME` [options] lat lon ...

DESCRIPTION
	Lat/Lon to RD (Dutch).

	http://www.dekoepel.nl/pdf/Transformatieformules.pdf

EXAMPLE
	Convert from DegDec:

	    $ ll2rd n52.01234 e5.01234
	    129264 447175

	Convert from MinDec:

	    $ ll2rd n52.01.201 e4.23.057
	    86160 448438

OPTIONS
	-D lvl		Debug level
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
    function round(A)	{ return int( A + 0.5 ) }
    function floor(x,   n)	{ n = int(x); if (n > x) --n; return (n) }
    function pow(a, b)      { return a ^ b }
    function tan(x)         { return sin(x)/cos(x) }
    function ConvertToString(x)         { return sprintf("%c", x) }
    function abs(x) { return (((x < 0) ? -x : x) + 0); }
    function fabs(x) { return (((x < 0.0) ? -x : x) + 0.0); }

    function LLtoRD(lat, lon)
    {
	dlat = 0.36*(lat - 52.15517440)
	dlon = 0.36*(lon - 5.38720621)
	r01 = 190094.945 
	r11 = -11832.228 
	r21 = -114.221 
	r03 = -32.391 
	r10 = -0.705 
	r31 = -2.340 
	r13 = -0.608 
	r02	= -0.008
	r23 = 0.148

	s10 = 309056.544
	s02	= 3638.893
	s20 = 73.077
	s12	= -157.984
	s30 = 59.788
	s01 = 0.433
	s22 = -6.439
	s11 = -0.032
	s04 = 0.092
	s14 = -0.054

	x = 155000 + r01*dlon + r11*dlat*dlon + r21*pow(dlat,2)*dlon \
	    + r03*pow(dlon,3) + r10*dlat + r31*pow(dlat,3)*dlon \
	    + r13*dlat*pow(dlon,3) + r02*pow(dlon,2) + r23*pow(dlat,2)*pow(dlon,3)
	y = 463000 + s10*dlat + s02*pow(dlon,2) + s20*pow(dlat,2) \
	    + s12*dlat*pow(dlon,2) + s30*pow(dlat,3) + s01*dlon \
	    + s22*pow(dlat,2)*pow(dlon,2) + s11*dlat*dlon + s04*pow(dlon,4) \
	    + s14*dlat*pow(dlon,4)
	print round(x), round(y)
    }

    BEGIN {
	LLtoRD(LAT, LON)
    }
    '
}

#
#	Main Program
#
process_latlon encode 0 $@
