#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Lat/long to US National Grid

SYNOPSIS
	`basename $PROGNAME` [options] lat lon ...

DESCRIPTION
	Lat/long to US National Grid.

	Also known as "Military Grid Reference System" (MGRS).

	https://usngcenter.org/portfolio-item/carto-tools/

EXAMPLE
	Convert:

	    $ ll2usng 44 -93.5
	    15T VJ 59913 71994

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
    awk -v LAT=$1 -v LON=$2 '
    function round(A)	{ return int( A + 0.5 ) }
    function floor(x,   n)	{ n = int(x); if (n > x) --n; return (n) }
    function pow(a, b)      { return a ^ b }
    function tan(x)         { return sin(x)/cos(x) }
    function ConvertToString(x)         { return sprintf("%c", x) }

    function findSet (zoneNum) {
	zoneNum = zoneNum % 6;
	if (zoneNum == 0) return 6
	if (zoneNum == 1) return 1
	if (zoneNum == 2) return 2
	if (zoneNum == 3) return 3
	if (zoneNum == 4) return 4
	if (zoneNum == 5) return 5
	return -1
    }

    function lettersHelper(set, row, col) {
	# handle case of last row
	if (row == 0)
	    row = GRIDSQUARE_SET_ROW_SIZE - 1
	else
	    row--

	# handle case of last column
	if (col == 0)
	    col = GRIDSQUARE_SET_COL_SIZE - 1
	else
	    col--

	if (set == 1)
	{
	    l1="ABCDEFGH"
	    l2="ABCDEFGHJKLMNPQRSTUV"
	    return substr(l1, col+1, 1) substr(l2, row+1, 1)
	}
	if (set == 2)
	{
	    l1="JKLMNPQR"
	    l2="FGHJKLMNPQRSTUVABCDE"
	    return substr(l1, col+1, 1) substr(l2, row+1, 1)
	}
	if (set == 3)
	{
	    l1="STUVWXYZ"
	    l2="ABCDEFGHJKLMNPQRSTUV"
	    return substr(l1, col+1, 1) substr(l2, row+1, 1)
	}
	if (set == 4)
	{
	    l1="ABCDEFGH"
	    l2="FGHJKLMNPQRSTUVABCDE"
	    return substr(l1, col+1, 1) substr(l2, row+1, 1)
	}
	if (set == 5)
	{
	    l1="JKLMNPQR"
	    l2="ABCDEFGHJKLMNPQRSTUV"
	    return substr(l1, col+1, 1) substr(l2, row+1, 1)
	}
	if (set == 6)
	{
	    l1="STUVWXYZ"
	    l2="FGHJKLMNPQRSTUVABCDE"
	    return substr(l1, col+1, 1) substr(l2, row+1, 1)
	}
    }

    function findGridLetters(zoneNum, northing, easting)
    {
	#zoneNum  = parseInt(zoneNum);
	#northing = parseFloat(northing);
	#easting  = parseFloat(easting);
	row = 1;

	# northing coordinate to single-meter precision
	north_1m = round(northing);

	# Get the row position for the square identifier that contains the point
	while (north_1m >= BLOCK_SIZE) {
	    north_1m = north_1m - BLOCK_SIZE;
	    row++;
	}

	# cycle repeats (wraps) after 20 rows
	row = row % GRIDSQUARE_SET_ROW_SIZE;
	col = 0;

	# easting coordinate to single-meter precision
	east_1m = round(easting)

	# Get the column position for the square identifier that contains the point
	while (east_1m >= BLOCK_SIZE){
	    east_1m = east_1m - BLOCK_SIZE;
	    col++;
	}

	# cycle repeats (wraps) after 8 columns
	col = col % GRIDSQUARE_SET_COL_SIZE;

	return lettersHelper(findSet(zoneNum), row, col);
    }

    # converts lat and lon to US National Grid
    function LLtoUSNG(lat, lon)
    {
	cmd = sprintf("ll2utm -m -- %s %s", lat, lon)
	cmd | getline UTMzoneNumber
	cmd | getline UTMletter
	cmd | getline UTMEasting
	cmd | getline UTMNorthing

	close(cmd)   
	if (lat < 0)
	    UTMNorthing += NORTHING_OFFSET
	#print UTMzoneNumber, UTMletter, UTMNorthing, UTMEasting

	USNGLetters  = findGridLetters(UTMzoneNumber, UTMNorthing, UTMEasting);
	USNGNorthing = round(UTMNorthing) % BLOCK_SIZE;
	USNGEasting  = round(UTMEasting)  % BLOCK_SIZE;
	#print USNGLetters, USNGNorthing, USNGEasting
	USNGNorthing = floor(USNGNorthing / pow(10, (5-precision)))
	USNGEasting = floor(USNGEasting / pow(10, (5-precision)))
	#print USNGNorthing, USNGEasting
	printf "%s%s %s %0*d %0*d\n", \
	    UTMzoneNumber, UTMletter, USNGLetters, \
		precision, USNGEasting, precision, USNGNorthing
    }

    BEGIN {
	GRIDSQUARE_SET_COL_SIZE = 8
	GRIDSQUARE_SET_ROW_SIZE = 20
	NORTHING_OFFSET = 10000000.0
	BLOCK_SIZE  = 100000
	precision = 5
	LLtoUSNG(LAT, LON)
    }
    '
}

#
#	Main Program
#
process_latlon encode 0 $@
