#!/bin/bash

#
#	geo-dist:
#		compute total distance between a set of waypoints
#
#	Requires: bash or ksh;
#		convert
#		xv
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-dist.sh,v 1.39 2016/04/08 13:29:55 rick Exp $
#

PROGNAME="$0"

usage() {
    
	cat <<EOF
NAME
    `basename $PROGNAME` - compute total distance between a set of waypoints

SYNOPSIS
    `basename $PROGNAME` [options] latitude longitude [label [symbol]] ...

DESCRIPTION
    Compute total distance and bearing between a set of waypoints.
    Acceptable formats for lat/lon are:

	-93.49130	DegDec (decimal degrees)
	W93.49130	DegDec (decimal degrees)
	"-93 29.478"	MinDec (decimal minutes)
	"W93 29.478"	MinDec (decimal minutes)
	-93.29.478	MinDec (decimal minutes)
	W93.29.478	MinDec (decimal minutes)
	W 93° 29.478	Cut/paste from gc.com (note it is 3 arguments)
	"-93 45 30"	DMS (degrees, minutes, seconds)

    "label" and "symbol" are optional, can be any text, and are ignored.
    They are accepted for compatibility with the command line input format
    of geo-map.

    If a lat/lon of 0/0 appears in the list, it is ignored and a new route
    is started.

OPTIONS
    -t waypts	A file of waypoints to plot in tabsep, GPX, or in
		extended Tiger format: LONG,LAT:SYMBOL:LABEL:URL
    -i          Incremental
    -g		true/false iff dist <= 2mi
    -v		Use Vincenty instead of 'rough'
    -D lvl	Debug level [$DEBUG]
    -U		Retrieve latest version of this script

EXAMPLES
    Two waypoints:

	$ geo-dist N44.48.938 W093.31.988 N44.49.245 W093.30.507
	1.258898mi      2.026km 2026m   6647ft  74.13

    Two waypoints, Vincenty formula:

	$ geo-dist -v N44.48.938 W093.31.988 N44.49.245 W093.30.507
	1.2632476mi     2.033km 2033m   6670ft  73.75

    Route in a GPX file:

	$ geo-dist -t bikeathon/bikewalk.gpx
	2.8129474mi     4.527km 4527m   14852ft 175.26

    Four waypoints:

	$ geo-dist -i 45 w93 44.59.809 -93.0.269 \\
		45.0.184 -93.0.269  45.0.375 -93.00.000

	1       0.31006422mi    0.499km 499m    1637ft  225.00
	2       0.43123161mi    0.694km 694m    2277ft  0.00
	3       0.31006422mi    0.499km 499m    1637ft  44.92
	TOTAL   1.0513601mi     1.692km 1692m   5551ft  0.00

SEE ALSO
    geo-code, geo-nearest, geo-pg, geo-waypoint,
    $WEBHOME
EOF

	exit 1
}

#include "geo-common"

#
# Floating point min/max
#
fmin() {
    awk -v m=$1 -v v=$2 'BEGIN{if (v<m) print v; else print m}'
}
fmax() {
    awk -v m=$1 -v v=$2 'BEGIN{if (v>m) print v; else print m}'
}

#
# Rough calculation of distance on an ellipsoid
#
calc_dist_meters() {
    awk \
    -v LATmin=$1 \
    -v LONmin=$2 \
    -v LATmax=$3 \
    -v LONmax=$4 \
    -v VIN=$VIN \
    '
    function asin(x)    { return atan2(x,(1.-x^2)^0.5) }
    function atan(x)    { return atan2(x, 1.0) }
    function abs(x)	    { return (x>=0) ? x : -x }
    function tan(x)     { return sin(x)/cos(x) }
    function isNaN(v)   { return 0 }

    # http://jsperf.com/vincenty-vs-haversine-distance-calculations
    # http://en.wikipedia.org/wiki/Vincenty%27s_formulae
    function distVincenty(lat1, lon1, lat2, lon2) {
	M_PI = 3.14159265358979323846
	M_PI_2 = 2 * M_PI
	M_PI_180 = M_PI / 180.0
	a = 6378137
	b = 6356752.314245
	f = 1/298.257223563		# WGS-84 ellipsoid params
	L = (lon2-lon1) * M_PI_180
	U1 = atan((1-f) * tan(lat1 * M_PI_180));
	U2 = atan((1-f) * tan(lat2 * M_PI_180));
	sinU1 = sin(U1); cosU1 = cos(U1);
	sinU2 = sin(U2); cosU2 = cos(U2);

	lambda = L; lambdaP = 100; iterLimit = 100
	do {
	    sinLambda = sin(lambda); cosLambda = cos(lambda);
	    sinSigma = sqrt((cosU2*sinLambda) * (cosU2*sinLambda) + \
		(cosU1*sinU2-sinU1*cosU2*cosLambda) * \
		(cosU1*sinU2-sinU1*cosU2*cosLambda))
	    if (sinSigma==0) return 0;  # co-incident points
	    cosSigma = sinU1*sinU2 + cosU1*cosU2*cosLambda;
	    sigma = atan2(sinSigma, cosSigma);
	    sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
	    cosSqAlpha = 1 - sinAlpha*sinAlpha;
	    cos2SigmaM = cosSigma - 2*sinU1*sinU2/cosSqAlpha;
	    if (isNaN(cos2SigmaM))
		cos2SigmaM = 0;  # equatorial line: cosSqAlpha=0 (§6)
	    C = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha));
	    lambdaP = lambda
	    lambda = L + (1-C) * f * sinAlpha * \
	      (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)));
	} while (abs(lambda-lambdaP) > 1e-12 && --iterLimit>0);

	if (iterLimit==0) return NaN  # formula failed to converge

	uSq = cosSqAlpha * (a*a - b*b) / (b*b);
	A = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
	B = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));
	deltaSigma = B*sinSigma*(cos2SigmaM+B/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)- \
	    B/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
	s = b*A*(sigma-deltaSigma);

	# s = s.toFixed(3); # round to 1mm precision
	bearing1 = atan2( \
			cosU2 * sin(lambda), \
			(cosU1 * sinU2 - sinU1 * cosU2 * cos(lambda)) \
		    )
	bearing2 = atan2( \
			cosU1 * sin(lambda), \
			(-sinU1 * cosU2 + cosU1 * sinU2 * cos(lambda)) \
		    )
	bearing[1] = (360 + bearing1 * 180.0 / M_PI) % 360.0
	bearing[2] = (360 + bearing2 * 180.0 / M_PI) % 360.0
	return s;
    }

    function calcR(lat)
    {
        lat = lat * M_PI_180
        sc = sin(lat)
        x = A * (1.0 - E2)
        z = 1.0 - E2 * sc * sc
        y = z ^ 1.5
        r = x / y
        return r * 1000.0
    }

    function dist(lat1, lon1, lat2, lon2,
                    radiant, dlon, dlat, a1, a2, a, sa, c)
    {
        radiant = M_PI_180
        dlon = radiant * (lon1 - lon2);
        dlat = radiant * (lat1 - lat2);
        a1 = sin(dlat / 2.0)
        a2 = sin (dlon / 2.0)
        a = (a1 * a1) + cos(lat1 * radiant) * cos(lat2 * radiant) * a2 * a2
        sa = sqrt(a)
        if (sa <= 1.0)
            c = 2 * asin(sa)
        else
            c = 2 * asin(1.0)
        return (Ra[int(100 + lat2)] + Ra[int(100 + lat1)]) * c / 2.0;
    }
    function bear(lat1, lon1, lat2, lon2)
    {
	command = sprintf("ll2utm -- %s %s", lat1, lon1)
        command | getline;
        x0 = $3
        y0 = $4
	command = sprintf("ll2utm -- %s %s", lat2, lon2)
        command | getline;
        x1 = $3
        y1 = $4

	rise = y1 - y0
	run = x1 - x0
	if (run)
	    slope = (rise + 0.0) / run
	else if (y0 >= y1)
	    { return 180; exit }
	else
	    { return 0; exit }
	
	radians = atan(slope)
	deg = radians * 180.0 / M_PI
	if (x0 <= x1)
	    deg = 90 - deg;
	else 
	    deg = 360 - (90 + deg)
	return deg
    }

    BEGIN {
        A = 6378.137
        E2 = 0.081082 * 0.081082
        M_PI = 3.14159265358979323846
        M_PI_2 = 2 * M_PI
        M_PI_180 = M_PI / 180.0
        # Build array for earth radii
        for (i = -100; i <= 100; i++)
            Ra[i+100] = calcR(i)

	if (VIN)
	{
	    d = distVincenty(LATmin, LONmin, LATmax, LONmax)
	    printf "%d %f\n", d, bearing[1]
	}
	else
	{
	    d = dist(LATmin, LONmin, LATmax, LONmax)
	    b = bear(LATmin, LONmin, LATmax, LONmax)
	    printf "%d %f\n", d, b
	}
	# printf "%d\n", d
	# print bearing[1], bearing[2] > "/dev/stderr"
    }
    '
}

#
#	A temporary style for processing waypoint files.
#
make_temp_style() {
    CRUFT="$CRUFT $1"
    cat <<-EOF > $1
	FIELD_DELIMITER		^
	RECORD_DELIMITER        NEWLINE
	BADCHARS                ^
	IFIELD	LAT_DECIMAL,	"",	"%.6f"
	IFIELD	LON_DECIMAL,	"",	"%.6f"
	IFIELD	ICON_DESCR,	"",	"%s"
	IFIELD	DESCRIPTION,	"",	"%s"
	IFIELD	URL,		"",	"%s"
	EOF
}

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/geo-dist
UPDATE_FILE=geo-dist.new

read_rc_file

#
#       Process the options
#
INCR=0
RC=0
TIGER=
VIN=0
DOGC=0
while getopts "girut:vD:U?-" opt
do
	case $opt in
	g)	DOGC="1";;
	i)	INCR="1";;
	r)	RC="1";;
	t)	TIGER="$OPTARG";;
	v)	VIN="1";;
	D)	DEBUG="$OPTARG";;
	U)	echo "Getting latest version of this script..."
		curl $CURL_OPTS -o$UPDATE_FILE "$UPDATE_URL"
		chmod +x "$UPDATE_FILE"
		echo "Latest version is in $UPDATE_FILE"
		exit
		;;
	\?|-)	usage;;
	esac
done
shift `expr $OPTIND - 1`

if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

#
#	Walk the command line args and place them into arrays
#
LATcenter=
LONcenter=
Npts=0
LATmin=999; LATmax=-999
LONmin=999; LONmax=-999
while [ $# -ge 2 ]; do
    case "$1" in
    N|S|n|s)
	if [ $# -ge 6 ]; then
	    # Allow cut and paste from geocaching.com cache page
	    # N 44° 58.630 W 093° 09.310
	    LAT=`echo "$1$2.$3" | tr -d '\260\302' `
	    LAT=`latlon $LAT`
	    LON=`echo "$4$5.$6" | tr -d '\260\302' `
	    LON=`latlon $LON`
	    shift 6
	else
	    error "Illegal lat/lon: $*"
	fi
	;;
    *)
	LAT=`latlon $1`
	LON=`latlon $2`
	shift 2
	;;
    esac

    #
    #	Default label and symbol
    #
    LABEL="`degdec2mindec $LAT` `degdec2mindec $LON`"
    SYMBOL=cross,red,10

    #
    #	Determine if user has supplied a label and symbol
    # 
    if [ "$#" -ge 1 ]; then
	if ! is_latlon "$@"; then
	    if [ "$1" != "@" ]; then
		LABEL="$1"
	    fi
	    shift

	    if [ "$#" -ge 1 ]; then
		if ! is_latlon "$@"; then
		    if [ "$1" != "@" ]; then
			SYMBOL="$1"
		    fi
		    shift
		fi
	    fi
	fi
    fi

    LATmin=`fmin $LATmin $LAT`
    LATmax=`fmax $LATmax $LAT`
    LONmin=`fmin $LONmin $LON`
    LONmax=`fmax $LONmax $LON`
    Lat[Npts]="$LAT"
    Lon[Npts]="$LON"
    Label[Npts]="$LABEL"
    Symbol[Npts]="$SYMBOL"
    Url[Npts]="NONE"
    LLlabel[Npts]="`degdec2mindec $LAT` `degdec2mindec $LON`"
    ((++Npts))
done

#
#	Read the tiger data into our arrays.
#
if [ "$TIGER" != "" ]; then
    if [ ! -f "$TIGER" ]; then
	error "Tiger file '$TIGER'  doesn't exist."
    fi
    if [ ! -s "$TIGER" ]; then
	error "Tiger file '$TIGER' is empty."
    fi
    if [ $Npts -ge 1 ]; then
	LATcenter=`awk -v v1=$LATmin -v v2=$LATmax 'BEGIN{print (v1+v2)/2}'`
	LONcenter=`awk -v v1=$LONmin -v v2=$LONmax 'BEGIN{print (v1+v2)/2}'`
    fi

    #
    # Figure out what kind of waypont file we have
    #
    read hdr < $TIGER

    IFMT=
    case "$hdr" in
    *tms-marker*)
	#
	# The gpsbabel tiger file reader throws away the icon name,
	# so we must process this file type "by hand".
	#
	OIFS="$IFS"
	IFS=":"
	goturl=0
	while read coord SYMBOL LABEL URL
	do
	    case "$coord" in
	    "#"*) continue;;
	    esac
	    LON=`echo $coord | sed 's/,.*//'`
	    LAT=`echo $coord | sed 's/.*,//'`

	    LATmin=`fmin $LATmin $LAT`
	    LATmax=`fmax $LATmax $LAT`
	    LONmin=`fmin $LONmin $LON`
	    LONmax=`fmax $LONmax $LON`
	    Lat[Npts]="$LAT"
	    Lon[Npts]="$LON"
	    Label[Npts]="$LABEL"
	    Symbol[Npts]="$SYMBOL"
	    Url[Npts]="$URL"
	    LLlabel[Npts]="`degdec2mindec $LAT` `degdec2mindec $LON`"
	    ((++Npts))
	    if [ "$URL" != "" ]; then
		goturl=1
	    fi
	done < $TIGER
	IFS="$OIFS"
	if [ $goturl = 0 -a "$IMAGEMAP" != "" ]; then
	    error "Cannot make image map with this tiger file (No URLs!)"
	fi
	;;
    *\	*)	IFMT=tabsep ;;
    "<?xml"*)	IFMT=gpx ;;
    *)
	error "Cannot handle this format, use tiger, tabsep or GPX"
	;;
    esac

    #
    #	Process reasonable formats generically
    #
    if [ "$IFMT" != "" ]; then
	#
	# Convert the waypoint file to our termporary format
	#
	TMPSTYLE=${TMP}-style.tmp
	make_temp_style $TMPSTYLE
	TMPWAY=${TMP}-way.tmp
	CRUFT="$CRUFT $TMPWAY"

	gpsbabel -i $IFMT -f $TIGER -o xcsv,style=$TMPSTYLE -F $TMPWAY

	#
	# Now read the waypoints into shell arrays
	#
	OIFS="$IFS"
	IFS="^"
	while read LAT LON SYMBOL LABEL URL
	do
	    LATmin=`fmin $LATmin $LAT`
	    LATmax=`fmax $LATmax $LAT`
	    LONmin=`fmin $LONmin $LON`
	    LONmax=`fmax $LONmax $LON`
	    Lat[Npts]="$LAT"
	    Lon[Npts]="$LON"
	    Label[Npts]="$LABEL"
	    Symbol[Npts]="$SYMBOL"
	    Url[Npts]="$URL"
	    LLlabel[Npts]="`degdec2mindec $LAT` `degdec2mindec $LON`"
	    ((++Npts))
	done < $TMPWAY
	IFS="$OIFS"
    fi

    #
    #	Compute the center
    #
    if [ "$LATcenter" = "" ]; then
	LATcenter=`awk -v v1=$LATmin -v v2=$LATmax 'BEGIN{print (v1+v2)/2}'`
	LONcenter=`awk -v v1=$LONmin -v v2=$LONmax 'BEGIN{print (v1+v2)/2}'`
    fi
else
    if [ $Npts -lt 1 ]; then
	error "Must supply at least one coordinate on the command line"
    elif [ $Npts -gt 1 ]; then
	LATcenter=`awk -v v1=$LATmin -v v2=$LATmax 'BEGIN{print (v1+v2)/2}'`
	LONcenter=`awk -v v1=$LONmin -v v2=$LONmax 'BEGIN{print (v1+v2)/2}'`
    else
	LATcenter="${Lat[0]}"
	LONcenter="${Lon[0]}"
    fi
fi

#
#	dounits amt units
#
dounits() {
    amt=$1
    units=$2
    units "$amt" "$units" | tail -2 | head -1 | sed 's/^	\* //'
}

((i=1))
meters=0
while ((i < Npts)); do
    LAT1=${Lat[i-1]}
    LON1=${Lon[i-1]}
    LAT2=${Lat[i]}
    LON2=${Lon[i]}
    if [ 0 != "$LAT2" -a 0 != "$LON2" ]; then
	rc=`calc_dist_meters $LAT1 $LON1 $LAT2 $LON2`
	d=`echo "$rc" | awk '{print $1}'`
	b=`echo "$rc" | awk '{print $2}'`
	# b=`calc_bearing $LAT1 $LON1 $LAT2 $LON2`
	((meters+=d))
	if [ $INCR = 1 ]; then
	    miles=$(dounits "$meters meters" miles)
	    km=$(dounits "$meters meters" km)
	    ft=$(dounits "$meters meters" feet)
	    printf "%d	%smi	%skm	%sm	%.0fft	%.2f\n" \
		$i $miles $km $d $ft $b
	fi
    else
	((++i))
    fi
    ((++i))
done

miles=$(dounits "$meters meters" miles)
km=$(dounits "$meters meters" km)
ft=$(dounits "$meters meters" feet)
if [ $RC = 1 ]; then
    ift=$(echo "$ft" | sed -e 's/[.].*//' )
    if [ $ift -gt 527 ]; then
	exit 0
    else
	exit 1
    fi
fi

((l=Npts-1))
rc=`calc_dist_meters ${Lat[0]} ${Lon[0]} ${Lat[$l]} ${Lon[$l]}`
b=`echo "$rc" | awk '{print $2}'`

if [ $INCR = 1 ]; then
     printf "TOTAL	%smi	%skm	%sm	%.0fft	%.3f\n" \
	$miles $km $meters $ft $b
else
    if [ $DOGC = 1 ]; then
	case "$miles" in
	0.*|1.*)	printf "1\n";;
	*)		printf "0\n";;
	esac
    else
	printf "%smi	%skm	%sm	%.0fft	%.3f\n" \
	    $miles $km $meters $ft $b
    fi
fi
