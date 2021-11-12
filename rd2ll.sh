#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - RD (Dutch) to Lat/lon

SYNOPSIS
	`basename $PROGNAME` [options]

DESCRIPTION
	RD (Dutch) to Lat/lon.

	http://www.dekoepel.nl/pdf/Transformatieformules.pdf

EXAMPLE
	Convert to DegDec:

	    $ rd2ll 86160 448438 
	    52.02 4.38429

	Convert to RickDec:

	    $ rd2ll -orickdec 86160 448438 
	    n52.01.201 e4.23.057

OPTIONS
	-l		Print latitude only
	-L		Print longitude only
	-odegdec	Print lat/lon in DegDec format (default)
	-omindec	Print lat/lon in MinDec format
	-orickdec	Print lat/lon in dotted MinDec format
	-odms		Print lat/lon in DMS format
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
FMT=degdec
LatOnly=0
LonOnly=0
while getopts "lLo:D:h?" opt
do
	case $opt in
	l)	LatOnly=1;;
	L)	LonOnly=1;;
	o)	FMT="$OPTARG";;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$#" in
2)
	X=$1
	Y=$2
	if [ 13677 -gt "$X" -o "$X" -gt 277977 ]; then
	    error "east coord '$X' not in range!"
	fi
	if [ 306628 -gt "$Y" -o "$Y" -gt 619290 ]; then
	    error "north coord '$Y' not in range!"
	fi
        ;;
*)
        usage
        ;;
esac

#
#	Main Program
#
awk -v X=$X -v Y=$Y -v FMT=$FMT -v LatOnly=$LatOnly -v LonOnly=$LonOnly '
function round(A)	{ return int( A + 0.5 ) }
function floor(x,   n)	{ n = int(x); if (n > x) --n; return (n) }
function pow(a, b)      { return a ^ b }
function tan(x)         { return sin(x)/cos(x) }
function ConvertToString(x)         { return sprintf("%c", x) }
function abs(x) { return (((x < 0) ? -x : x) + 0); }
function fabs(x) { return (((x < 0.0) ? -x : x) + 0.0); }

function outfmt(coord, lets,	deg, min, fmin, sec)
{
    let = (coord >= 0) ? substr(lets,1,1) : substr(lets,2,1)

    if (FMT == "degdec")
	printf("%f", coord)
    else if (FMT == "mindec")
    {
	deg = int(coord)
	min = fabs(coord - deg) * 60.0
	printf("%c%02d %s%.3f", let, abs(deg), (min < 10) ? "0" : "", min)
    }
    else if (FMT == "rickdec")
    {
	deg = int(coord)
	min = fabs(coord - deg) * 60.0
	printf("%c%02d.%s%.3f", let, abs(deg), (min < 10) ? "0" : "", min)
    }
    else if (FMT == "dms")
    {
	deg = int(coord)
	fmin = fabs(coord - deg) * 60.0
	min = int(fmin)
	sec = int( (fmin-min) * 60.0 )
	printf("%d %02d %02d", deg, min, sec)
    }
    else
    {
	print "Format not implemented yet"
	exit
    }
}

# converts lat and lon to US National Grid
function RDtoLL(x, y)
{
rijksX = (x-155000)/100000
rijksY = (y-463000)/100000
# border coordinates?
k01=3235.65389
k20=-32.58297
k02=-0.24750
k21=-0.84978
k03=-0.06550
k22=-0.01709
k10=-0.00738
k40=0.00530
k23=-0.00039
k41=0.00033
k11=-0.00012
l10=5260.52916
l11=105.94684
l12=2.45656
l30=-0.81885
l13=0.05594
l31=-0.05607
l01=0.01199
l32=-0.00256
l14=0.00128
l02=0.00022
l20=-0.00022
l50=0.00026
lat = 52.15517440 + ( (1/3600)* \
((k01*rijksY)+(k20*pow(rijksX,2))+(k02*pow(rijksY,2))+(k21*pow(rijksX,2)*rijksY)+(k03*pow(rijksY,3))+(k22*pow(rijksX,2)*pow(rijksY,2))+(k10*rijksX)+(k40*pow(rijksX,4))+(k23*pow(rijksX,2)*pow(rijksY,3))+(k41*pow(rijksX,4)*rijksY)+(k11*rijksX*rijksY)))

lon = 5.38720621+((1/3600)*((l10*rijksX)+(l11*rijksX*rijksY)+(l12*rijksX*pow(rijksY,2))+(l30*pow(rijksX,3))+(l13*rijksX*pow(rijksY,3))+(l31*pow(rijksX,3)*rijksY)+(l01*rijksY)+(l32*pow(rijksX,3)*pow(rijksY,2))+(l14*rijksX*pow(rijksY,4))+(l02*pow(rijksY,2))+(l20*pow(rijksX,2))+(l50*pow(rijksX,5))))

	if (!LatOnly && !LonOnly)
        {
            outfmt(lat, "ns")
            printf(" ")
            outfmt(lon, "ew")
            printf("\n")
        }
        else
        {
            if (LatOnly)
            {
                outfmt(lat, "ns")
                printf("\n")
            }
            if (LonOnly)
            {
                outfmt(lon, "ew")
                printf("\n")
            }
        }
}

BEGIN {
    RDtoLL(X, Y)
}
'
