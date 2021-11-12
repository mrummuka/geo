#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Maidenhead (Grid Squares) to Lat/long

SYNOPSIS
	`basename $PROGNAME` [options] grid ...

DESCRIPTION
    Maidenhead (a.k.a. Grid Squares) to Lat/long

EXAMPLES
    Convert:

	$ maidenhead2ll EN10PT DM79MR
	EN10PT  40.812500 -96.708330    n40.48.750 w96.42.500
	DM79MR  39.729170 -104.958330   n39.43.750 w104.57.500

    Convert, full precidsion:

	$ maidenhead2ll -f EN10PT
	EN10PT  40.812500 -96.708330    n40.48.750 w96.42.500

    Convert, full precision:

	$ maidenhead2ll en35lb60ub29
	EN35LB60UB29    45.041997 -93.026319    n45.02.520 w93.01.579

OPTIONS
	-f	Full precision
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
DOLAT=0
DOLON=0
FULL=0
while getopts "fD:h?" opt
do
	case $opt in
	f)	FULL=1;;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
doit() {
    GRID=$1
    awk -v GRID="$GRID" -v FULL=$FULL '
    function abs(x)         { return (x>=0) ? x : -x }
    function char(v) { return v }
    function num2str(v) { return v }
    function _ord_init(    low, high, i, t)
    {
	low = sprintf("%c", 7) # BEL is ascii 7
	if (low == "\a") {    # regular ascii
	    low = 0
	    high = 127
	} else if (sprintf("%c", 128 + 7) == "\a") {
	    # ascii, mark parity
	    low = 128
	    high = 255
	} else {        # ebcdic(!)
	    low = 0
	    high = 255
	}

	for (i = low; i <= high; i++) {
	    t = sprintf("%c", i)
	    _ord_[t] = i
	}
    }
    function ord(str,    c)
    {
	# only first character is of interest
	c = substr(str, 1, 1)
	return _ord_[c]
    }
    function chr(c)
    {
	# force c to be numeric by adding 0
	return sprintf("%c", c + 0)
    }
    function f(z)
    {
	if (z==-1) return 10
	if (z==0) return 1
	if (z==1) return 0.0416666666667
	if (z==2) return 0.00416666666667
	if (z==3) return 0.000173611111111
	if (z==4) return 1.73611111111e-05
	if (z==5) return 7.2337962963e-07
	if (z==6) return 7.2337962963e-08
	if (z==7) return 3.01408179012e-09
	if (z==8) return 3.01408179012e-10
	print "error"
	return 0
	#return (10^((-(z-1)/2))*24)^(-(z/2))
    }
    function GRIDtoLL(gridstr)
    {
	gridstr = toupper(gridstr)
	if (FULL == 0 && length(gridstr) <= 6)
	{
	    # Old way
	    ngrid = split(gridstr, grid, "")
	    lon = ((ord(grid[1]) - ord("A")) * 20) - 180;
	    lat = ((ord(grid[2]) - ord("A")) * 10) - 90;
	    lon += ((ord(grid[3]) - ord("0")) * 2);
	    lat += ((ord(grid[4]) - ord("0")) * 1);
	    if (ngrid >= 5)
	    {
		# have subsquares
		lon += ((ord(grid[5])) - ord("A")) * (5/60);
		lat += ((ord(grid[6])) - ord("A")) * (2.5/60);
		# move to center of subsquare
		lon += (2.5/60);
		lat += (1.25/60);
		# not too precise
		formatter = "%.5f";
	    }
	    else
	    {
		# move to center of square
		lon += 1;
		lat += 0.5;
		# even less precise
		formatter = "%.1f";
	    }
	}
	else
	{
	    # New way
	    lets = gridstr
	    nums = gridstr
	    gsub("[^A-Z]", "", lets)
	    gsub("[^0-9]", "", nums)
	    # print lets, nums
	    for (i = 1; i <= length(lets); i += 2)
		valx[i] = ord(substr(lets, i, 1)) - ord("A")
	    for (i = 2; i <= length(lets); i += 2)
		valy[i-1] = ord(substr(lets, i, 1)) - ord("A")
	    for (i = 1; i <= length(nums); i += 2)
		valx[i+1] = substr(nums, i, 1)
	    for (i = 2; i <= length(nums); i += 2)
		valy[i] = substr(nums, i, 1)
	    tot = length(lets)/2 + length(nums)/2
	    # print tot, f(0), f(1), f(2)
	    if (0)
		for (i = 1; i <= tot; ++i)
		    print valx[i], valy[i]
	    lon = -90
	    lat = -90
	    for (i = 1; i <= tot; ++i)
	    {
		# print f(i-2), i-1
		lon += f(i-2) * valx[i]
		lat += f(i-2) * valy[i]
	    }
	    lon *= 2
	    formatter = "%.6f";
	}
	lat = sprintf(formatter, lat);
	lon = sprintf(formatter, lon);
	 
	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("        ");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "%s	%f %f", gridstr, lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "	%s%d.%06.3f %s%d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}
    }

    BEGIN {
	_ord_init()
	GRIDtoLL(GRID)
    }
    '
}

for i in $*; do
    doit $i
done
