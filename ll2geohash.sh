#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Lat/long to geohash

SYNOPSIS
	`basename $PROGNAME` [options] lat lon ...

DESCRIPTION
	Lat/long to geohash.

	http://en.wikipedia.org/wiki/Geohash

EXAMPLE
	Convert:

	    $ ll2geohash n35.44.000 w79.28.832
	    dnr7r3h1c254

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
    $awk -v LAT=$1 -v LON=$2 '
    function round(A)	{ return int( A + 0.5 ) }
    function floor(x,   n)	{ n = int(x); if (n > x) --n; return (n) }
    function pow(a, b)      { return a ^ b }
    function tan(x)         { return sin(x)/cos(x) }
    function ConvertToString(x)         { return sprintf("%c", x) }

    function encodeGeoHash(latitude, longitude) {
	is_even=1;
	i=0;
	bit=0;
	ch=0;
	precision = 12;
	geohash = "";

	lat[0] = -90.0;  lat[1] = 90.0;
	lon[0] = -180.0; lon[1] = 180.0;

	while (length(geohash) < precision)
	{
	    if (is_even)
	    {
		mid = (lon[0] + lon[1]) / 2;
		if (longitude > mid)
		{
		    ch = or(ch, BITS[bit])
		    #ch |= BITS[bit];
		    lon[0] = mid;
		}
		else
		    lon[1] = mid;
	    }
	    else
	    {
		mid = (lat[0] + lat[1]) / 2;
		if (latitude > mid)
		{
		    ch = or(ch, BITS[bit])
		    #ch |= BITS[bit];
		    lat[0] = mid;
		}
		else
		    lat[1] = mid;
	    }

	    is_even = !is_even;
	    if (bit < 4)
		bit++;
	    else
	    {
		geohash = geohash substr(BASE32, ch+1, 1)
		bit = 0;
		ch = 0;
	    }
	}
	return geohash;
    }

    BEGIN {
	BITS[0] = 16; BITS[1] = 8; BITS[2] = 4; BITS[3] =  2; BITS[4] = 1
	BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"
	print encodeGeoHash(LAT, LON)
    }
    '
}

#
#	Main Program
#
process_latlon encode 0 $@
