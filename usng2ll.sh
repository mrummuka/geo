#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - US National Grid to Lat/long

SYNOPSIS
	`basename $PROGNAME` [options]

DESCRIPTION
	US National Grid to Lat/lon.

	Also known as "Military Grid Reference System" (MGRS).

	https://usngcenter.org/portfolio-item/carto-tools/

EXAMPLE
	Convert:

	    $ usng2ll 17R LN 64066 80742
	    wp = 29.649226 -82.404421    n29.38.954 w82.24.265

	    $ usng2ll 15T VJ 22779 63998
	    wp = 43.925049 -93.961954    n43.55.503 w93.57.717

	    $ usng2ll 46T EP 77220 63998
	    wp = 43.925049 93.961942    n43.55.503 e93.57.717

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
4)
	ZZL="$1"
	LL="$2"
	EAST="$3"
	NORTH="$4"
        ;;
*)
        usage
        ;;
esac

#
#	Main Program
#
awk -v ZZL="$ZZL" -v LL="$LL" -v EAST="$EAST" -v NORTH="$NORTH" '
function abs(x)		{ return (x>=0) ? x : -x }
function round(A)	{ return int( A + 0.5 ) }
function floor(x,   n)	{ n = int(x); if (n > x) --n; return (n) }
function pow(a, b)      { return a ^ b }
function tan(x)         { return sin(x)/cos(x) }
function ConvertToString(x)         { return sprintf("%c", x) }

function latBandMidpointLatitude(latBandLetter)
{
    if (latBandLetter == "X")
        # the northernmost band X is 12 degrees wide, special case
        return 78
    else
    {
        # southernmost band C has midpoint at 76 South, 8 degrees per band
        gzdIndex = index(GZD_LETTERS, latBandLetter) - 1
        return -76 + gzdIndex * 8
    }
}

function latBandMidpointRowIndex(latBandLetter)
{
    lat = latBandMidpointLatitude(latBandLetter)
    cmd = sprintf("ll2utm -n -- %s %s", lat, 0)
    cmd | getline northing
    close(cmd)
    # _easting, northing, _zoneNumber, _zoneLetter = LLtoUTM(lat, 0)
    return northing / BLOCK_SIZE
}

# converts US National Grid to lat/lon
function USNG2LL(zone, let, sq1, sq2, east, north)
{
    # see FGDC-STD-011-2001 page 10
    colLetter = sq1
    colSet = ((zone - 1) % 3)
    colIndex0 = index(USNG_LETTERS, colLetter) - 1
    colIndex = colIndex0 + 1 - GRIDSQUARE_SET_COL_SIZE * colSet

    rowLetter = sq2
    rowSet = ((zone - 1) % 2)
    rowIndex0 = index(USNG_LETTERS, rowLetter) - 1
    rowIndex1 = rowIndex0 - 5 * rowSet

    latBandLetter = let
    latBandRowIndex = latBandMidpointRowIndex(latBandLetter)

    # choose numCycles such that rowIndex is as close as possible to
    # latBandRowIndex.  because a set of 20 rows is much taller than a
    # latitude band, the rounding operation should never be a "close
    # call".
    numCycles = int(round((latBandRowIndex - rowIndex0) / GRIDSQUARE_SET_ROW_SIZE))
    rowIndex = numCycles * GRIDSQUARE_SET_ROW_SIZE + rowIndex1

    N = rowIndex * BLOCK_SIZE + north * pow(10, 5 - length(north))
    E = colIndex * BLOCK_SIZE + east * pow(10, 5 - length(east))
    # print zone, let, E, N
    cmd = sprintf("utm2ll -- %s %s %s %s", zone, let, E, N)
    cmd | getline; lat = $1; lon = $2
    close(cmd)
    # lon = -lon	# WHAT!  TODO
    # print lat, lon
    if (DOLAT || DOLON)
    {
	if (DOLAT) printf("%f", lat);
	if (DOLAT && DOLON) printf("        ");
	if (DOLON) printf("%f", lon);
	printf("\n");
    }
    else
    {
	printf "wp = %f %f", lat, lon
	ilat = int(lat); ilon = int(lon)
	printf "    %s%d.%06.3f %s%d.%06.3f", \
	    lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
	    lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	printf "\n"
    }
}

BEGIN {
    GRIDSQUARE_SET_COL_SIZE = 8
    GRIDSQUARE_SET_ROW_SIZE = 20
    NORTHING_OFFSET = 10000000.0
    BLOCK_SIZE  = 100000
    GZD_LETTERS = "CDEFGHJKLMNPQRSTUVWX"
    USNG_LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ"

    zone = ZZL; let = ZZL
    gsub("[a-zA-Z]", "", zone)
    gsub("[^a-zA-Z]", "", let)
    #print zone, let
    sq1 = substr(LL, 1, 1)
    sq2 = substr(LL, 2, 1)
    precision = length(NORTH)
    east = EAST
    north = NORTH
    # print zone, let, sq1, sq2, precision, east, north
    USNG2LL(zone, let, sq1, sq2, east, north)
}
'
