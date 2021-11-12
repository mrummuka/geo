#!/bin/bash

#
#	geo-triangulation:
#		Compute the point by measuring angles
#
#	Requires: bash or ksh; awk
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-triangulation.sh,v 1.15 2015/05/02 22:43:31 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Compute the "point" by measuring angles

SYNOPSIS
	`basename $PROGNAME` [options] lat0 lon0 bear0 lat1 lon1 bear1 [ lat2 lon2 bear2 ]

DESCRIPTION
	Compute the "point" by measuring angles from/to locations.

	lat/lon can be specified in DegDec or dotted MinDec format.

	The bearing is in degrees from the location(s) to the "point", or
	negative degrees to the location(s) from the "point". I.E. the
	abs(bearing) plus 180 mod 360. The bearing can be suffixed with
	mil or grad.

	N.B. this program was inspired by Rock Johnson's "Gee" series of
	math caches.  Dyl1231, Seabiskit, and I enjoy these very much.
	Thanks RJ!

OPTIONS
	-f	Pretend that the world is flat
		and 1 degree latitude == 1 degree longitude
	-D lvl	Debug level

EXAMPLES
	MinDec input, from the locations to the "point" ...

	    $ geo-triangulation N41.09.810 W105.22.693 336.25 \\
				N41.09.882 W105.22.868 61.74 \\
				N41.10.101 W105.22.416 235.82
	    0-1:    N41.09.926 W105.22.760
	    0-2:    N41.09.925 W105.22.760
	    1-2:    N41.09.931 W105.22.746
	    Ave:    .927 .755

	MinDec input, from the "point" to the locations ...

	    $ geo-triangulation N41.09.810 W105.22.693 -156.25 \\
				N41.09.882 W105.22.868 -241.74 \\
				N41.10.101 W105.22.416 -55.82
	    0-1:    N41.09.926 W105.22.760
	    0-2:    N41.09.925 W105.22.760
	    1-2:    N41.09.931 W105.22.746
	    Ave:    .927 .755

	Two points ...

	    $ geo-triangulation N41.09.810 W105.22.693 -156.25 \\
				N41.09.882 W105.22.868 -241.74 
	    0-1:    N41.09.926 W105.22.760

EOF

	exit 1
}

#include "geo-common"

#
#       Process the options
#
DEBUG=0
FLAT=
while getopts "fD:h?" opt
do
	case $opt in
	f)	FLAT=-p;;
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
	BEAR0=$7
	shift 7
	LAT1=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT1=`latlon $LAT1`
	LON1=`echo "$4$5.$6" | tr -d '\260\302' `
	LON1=`latlon $LON1`
	BEAR1=$7
	shift 7
	LAT2=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT2=`latlon $LAT2`
	LON2=`echo "$4$5.$6" | tr -d '\260\302' `
	LON2=`latlon $LON2`
	BEAR2=$7
	shift 7
	POINTS=3
	;;
9)
	LAT0=`latlon $1`
	LON0=`latlon $2`
	BEAR0=$3
	shift 3
	LAT1=`latlon $1`
	LON1=`latlon $2`
	BEAR1=$3
	shift 3
	LAT2=`latlon $1`
	LON2=`latlon $2`
	BEAR2=$3
	shift 3
	POINTS=3
	;;
14)
	# Cut and paste from geocaching.com cache page
	# N 44° 58.630 W 093° 09.310
	LAT0=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT0=`latlon $LAT0`
	LON0=`echo "$4$5.$6" | tr -d '\260\302' `
	LON0=`latlon $LON0`
	BEAR0=$7
	shift 7
	LAT1=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT1=`latlon $LAT1`
	LON1=`echo "$4$5.$6" | tr -d '\260\302' `
	LON1=`latlon $LON1`
	BEAR1=$7
	shift 7
	POINTS=2
	;;
6)
	LAT0=`latlon $1`
	LON0=`latlon $2`
	BEAR0=$3
	shift 3
	LAT1=`latlon $1`
	LON1=`latlon $2`
	BEAR1=$3
	shift 3
	POINTS=2
	;;
*)
	usage
	;;
esac

#
#	Main Program
#
geo_tri() {
    bear0=$3
    case $bear0 in
    -*)	bear0=`echo "$bear0" | tr -d -`; bear0=`dc -e "$bear0 180 + 360 % p"`;;
    esac
    bear1=$6
    case $bear1 in
    -*)	bear1=`echo "$bear1" | tr -d -`; bear1=`dc -e "$bear1 180 + 360 % p"`;;
    esac
    latp0=`geo-project -l -- $1 $2 2mi $bear0`
    lonp0=`geo-project -L -- $1 $2 2mi $bear0`
    latp1=`geo-project -l -- $4 $5 2mi $bear1`
    lonp1=`geo-project -L -- $4 $5 2mi $bear1`
    printf "$7	"
    res=`geo-intersect $FLAT -- $1 $2 $latp0 $lonp0 $4 $5 $latp1 $lonp1`
    echo $res
    
    lat=` echo $res | sed -e 's/ .*//' -e 's/.*\.//' `
    lon=` echo $res | sed -e 's/.* //' -e 's/.*\.//' `
    lats="$lats $lat+"
    lons="$lons $lon+"
}

lats=0; lons=0
geo_tri $LAT0 $LON0 $BEAR0 $LAT1 $LON1 $BEAR1 "0-1:"
if [ $POINTS == 3 ]; then
    geo_tri $LAT0 $LON0 $BEAR0 $LAT2 $LON2 $BEAR2 "0-2:"
    geo_tri $LAT1 $LON1 $BEAR1 $LAT2 $LON2 $BEAR2 "1-2:"
    lat=`dc -e "$lats $POINTS/p"`
    lon=`dc -e "$lons $POINTS/p"`
    printf "Ave:	.%03d .%03d\n" $lat $lon
fi
