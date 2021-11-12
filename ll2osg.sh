#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Lat/long to British National Grid

SYNOPSIS
	`basename $PROGNAME` [options] lat lon ...

DESCRIPTION
	Lat/long to British National Grid, a.k.a. Ordnance Survey Grid.

	http://www.dorcus.co.uk/carabus/ll_ngr.html

EXAMPLE
	Convert from DegDec:

	    $ ll2osg 53.8826137384   -2.9290438893
	    338937 443358 SD 38937 43358

	Convert from MinDec:

	    $ ll2osg N53.52.957 W2.55.743
	    338936 443358 SD 38936 43358

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
    # http://www.dorcus.co.uk/carabus/ll_ngr.html
    # http://www.dorcus.co.uk/carabus/ngr_ll.html
    function pow(a, b)      { return a ^ b }
    function tan(x)         { return sin(x)/cos(x) }
    function ConvertToString(x)         { return sprintf("%c", x) }
    function Marc(bf0, n, phi0, phi)
    {
	return bf0 * (((1 + n + ((5 / 4) * (n * n)) + ((5 / 4) * (n * n * n))) \
	    * (phi - phi0)) \
	    - (((3 * n) + (3 * (n * n)) + ((21 / 8) * (n * n * n))) * \
	    (sin(phi - phi0)) * (cos(phi + phi0))) \
	    + ((((15 / 8) * (n * n)) + ((15 / 8) * (n * n * n))) * \
	    (sin(2 * (phi - phi0))) * (cos(2 * (phi + phi0)))) \
	    - (((35 / 24) * (n * n * n)) * (sin(3 * (phi - phi0))) * \
	    (cos(3 * (phi + phi0)))));
    }

    # converts lat and lon (OSGB36)  to OS 6 figure northing and easting
    function LLtoNE(lat, lon)
    {
	deg2rad = 0.0174532925199432957692369076848;
	phi = lat * deg2rad;          # convert latitude to radians
	lam = lon * deg2rad;          # convert longitude to radians
	a = 6377563.396;              # OSGB semi-major axis
	b = 6356256.91;               # OSGB semi-minor axis
	e0 = 400000;                  # easting of false origin
	n0 = -100000;                 # northing of false origin
	f0 = 0.9996012717;            # OSGB scale factor on central meridian
	e2 = 0.0066705397616;         # OSGB eccentricity squared
	lam0 = -0.034906585039886591; # OSGB false east
	phi0 = 0.85521133347722145;   # OSGB false north
	af0 = a * f0;
	bf0 = b * f0;

	# easting
	slat2 = sin(phi) * sin(phi);
	nu = af0 / (sqrt(1 - (e2 * (slat2))));
	rho = (nu * (1 - e2)) / (1 - (e2 * slat2));
	eta2 = (nu / rho) - 1;
	p = lam - lam0;
	IV = nu * cos(phi);
	clat3 = pow(cos(phi), 3);
	tlat2 = tan(phi) * tan(phi);
	V = (nu / 6) * clat3 * ((nu / rho) - tlat2);
	clat5 = pow(cos(phi), 5);
	tlat4 = pow(tan(phi), 4);
	VI = (nu / 120) * clat5 * ((5 - (18 * tlat2)) + tlat4 + (14 * eta2) \
	    - (58 * tlat2 * eta2));
	east = e0 + (p * IV) + (pow(p, 3) * V) + (pow(p, 5) * VI);

	# northing
	n = (af0 - bf0) / (af0 + bf0);
	M = Marc(bf0, n, phi0, phi);
	I = M + (n0);
	II = (nu / 2) * sin(phi) * cos(phi);
	III = ((nu / 24) * sin(phi) * pow(cos(phi), 3)) \
		* (5 - pow(tan(phi), 2) + (9 * eta2));
	IIIA = ((nu / 720) * sin(phi) * clat5) * (61 - (58 * tlat2) + tlat4);
	north = I + ((p * p) * II) + (pow(p, 4) * III) + (pow(p, 6) * IIIA);

	# make whole number values
	east = int(east);   # round to whole number
	north = int(north); # round to whole number

	printf "%d %d	", east, north

	# convert to nat grid ref
	NE2NGR(east, north);
    }

    #convert 12 (6e & 6n) figure numeric to letter and number grid system
    function NE2NGR(east, north)
    {
	eX = east / 500000;
	nX = north / 500000;
	tmp = int(eX) - 5.0 * int(nX) + 17.0;  
	nX = 5 * (nX - int(nX));
	eX = 20 - 5.0 * int(nX) + int(5.0 * (eX - int(eX)));
	if (eX > 7.5) eX = eX + 1;    # I is not used
	if (tmp > 7.5) tmp = tmp + 1; # I is not used

	eing = east + "";
	ning = north + "";
	lnth = length(eing);
	eing = substr(eing, lnth - 5 + 1);
	lnth = length(ning);
	ning = substr(ning, lnth - 5 + 1);
	ngr = ConvertToString(tmp + 65) ConvertToString(eX + 65) \
		" " eing " " ning;

	# Notify the calling application of the change
	# if (NatGridRefReceived != null) NatGridRefReceived(ngr);
	print ngr
    }
    BEGIN {
	LLtoNE(LAT, LON)
    }
    '
}

#
#	Main Program
#
process_latlon encode 0 $@
