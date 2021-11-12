#!/bin/bash

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Convert lat/lon from one format to another

SYNOPSIS
	`basename $PROGNAME` [options] latitude longitude

DESCRIPTION
	Convert lat/lon from one format to another.
	Lat/Lon may be in DegDec, MinDec, or DMS formats.

	Acceptable formats for lat/lon are:

	    -93.49130	    DegDec (decimal degrees)
	    W93.49130	    DegDec (decimal degrees)

	    "-93 29.478"    MinDec (decimal minutes)
	    "W93 29.478"    MinDec (decimal minutes)
	    -93.29.478	    MinDec (decimal minutes)
	    W93.29.478	    MinDec (decimal minutes)
	
	    "-93 45 30"	    DMS (degrees, minutes, seconds)

OPTIONS
	-a	Antipod (opposite side)
	-d	Output DegDec only
	-m	Output MinDec only
	-l	Lat only
	-L	Long only

EXAMPLE
	Convert DegDec:

	    $ geo-coords n45.12345 w93.12345
	      45.12345   -93.12345
	    N45.12345 W93.12345
	    N45 7' 24.420000" W93 7' 24.420000"
	    N45.07.407 W93.07.407

	Convert to antipod:

	    $ geo-coords -a s38.32.329 e58.13.715
	      38.538816   121.771417
	    N38.538816 E121.771417
	    N38 32' 19.737600" E121 46' 17.101200"
	    N38.32.329 E121.46.285

SEE ALSO
	ll2maidenhead, ll2osg, ll2rd, ll2usng, ll2utm,
	maidenhead2ll, rd2ll, usng2ll, utm2ll

EOF

	exit 1
}

#include "geo-common"

#
#       Set default options, can be overriden on command line or in rc file
#
DEBUG=0
DEGMIN=0
DEGDEC=0
DOLAT=0
DOLON=0
ANTI=0
read_rc_file

#
#       Process the options
#
while getopts "alLdmDh?-" opt
do
	case $opt in
	a)	ANTI="1";;
	d)	DEGDEC="1";;
	m)	DEGMIN="1";;
	l)	DOLAT="1";;
	L)	DOLON="1";;
	D)	DEBUG="$OPTARG";;
	h|\?|-)	usage;;
	esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
case "$#" in
6)
	# Cut and paste from geocaching.com cache page
	# N 44° 58.630 W 093° 09.310
	LAT=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT=`latlon $LAT`
	LON=`echo "$4$5.$6" | tr -d '\260\302' `
	LON=`latlon $LON`
	;;
4)
	LAT=`latlon $1.$2`
	LON=`latlon $3.$4`
	;;
2)
	LAT=`latlon $1`
	LON=`latlon $2`
	;;
*)
	usage
	;;
esac

if [ $ANTI = 1 ]; then
    LAT=`echo $LAT | awk '{ printf "%f\n", 0.0 - $1 }' `
    LON=`echo $LON | awk '{ printf "%f\n", $1>=0 ? -(180.0-$1) : 180.0+$1 }' `
fi

if [ $DEGMIN = 0 ]; then
    if [ $DOLAT = 1 ]; then
	echo "$LAT"
	exit
    elif [ $DOLON = 1 ]; then
	echo "$LON"
	exit
    fi
    echo "  $LAT   $LON"
    if [ $DEGDEC = 1 ]; then
	exit
    fi
fi

degdec2NSdegdec() {
    case "$1" in
    -*)	echo "$3$1" | tr -d -- -;;
    *)	echo "$2$1";;
    esac
}

degdec2NSmindec() {
    case "$1" in
    -*)	echo "$3$(degdec2mindec $1)" | tr -d -- -;;
    *)	echo "$2$(degdec2mindec $1)";;
    esac
}

degdec2NSdms() {
    case "$1" in
    -*)	echo "$3$(degdec2dms $1)" | tr -d -- -;;
    *)	echo "$2$(degdec2dms $1)";;
    esac
}

#
#       Convert DegDec to dms
#
degdec2dms() {
    awk -v v=$1 \
        'BEGIN{
	    d=int(v)
	    f=(v-d)*60
	    if(f<0)f=-f
	    m=int(f)
	    s=(f-m)*60
	    printf "%d %d'\'' %f\"\n", d, m, s
	}'
}

if [ $DEGMIN = 0 ]; then
    echo "$(degdec2NSdegdec $LAT N S) $(degdec2NSdegdec $LON E W)"
    echo "$(degdec2NSdms $LAT N S) $(degdec2NSdms $LON E W)"
else
    if [ $DOLAT = 1 ]; then
	echo "$(degdec2NSmindec $LAT N S)"
	exit
    elif [ $DOLON = 1 ]; then
	echo "$(degdec2NSmindec $LON E W)"
	exit
    fi
fi
echo "$(degdec2NSmindec $LAT N S) $(degdec2NSmindec $LON E W)"
