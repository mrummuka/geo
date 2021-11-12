#!/bin/bash

#
#	geo-code: Convert a street address into a latitude/longitude
#
#	Requires: curl; gpsbabel; bash or ksh;
#		  mysql (if using the gpsdrive.sql output option)
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-code.sh,v 1.28 2018/05/20 21:02:43 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Geocode an address into a lat/lon

SYNOPSIS
    `basename $PROGNAME` [options] address citystate_or_zip [country]
    `basename $PROGNAME` [options] "" citystate_or_zip [country]
    `basename $PROGNAME` [options] tele-phone-number

DESCRIPTION
    `basename $PROGNAME` [options] address citystate_or_zip [country]

	Convert (geocode) a street address into a latitude/longitude.

    `basename $PROGNAME` [options] "" citystate_or_zip [country]

	Convert (geocode) a place name into a latitude/longitude.

    `basename $PROGNAME` [options] tele-phone-number

	Convert (geocode) a phone number into a latitude/longitude.

    In either case, the output can be formatted to any of the output
    file types that gpsbabel supports, or directly imported into the
    GpsDrive MySQL waypoint database.

    Requires:
	curl		http://curl.haxx.se/
	gpsbabel	http://gpsbabel.sourceforge.net/

OPTIONS
	-o format	Output format, -o? for possibilities [$OUTFMT]
			plus "gpsdrive.sql" for direct insertion into MySQL DB
			plus "degdec" for just Lat.fraq<tab>Long.fraq.
			plus "mindec" for just DD MM.MMM<tab>DD MM.MMM.
			plus "map[,geo-map-opts]" to display a geo-map.
	-n name		The waypoint name, e.g. Bob's House.  The default
			is the street address.  Percent escapes can be used:
			%d/%D for DegDec lat/lon, %m/%M for MinDec lat/lon,
			%a for address, %c for citystate_or_zip, %p for phone
	-s		Output shortened names (a gpsbabel option)
	-t type		The waypoint type, e.g. house, cache, bar [$CODETYPE]
	-q		Quiet. Do not output address confirmation on stderr.
	-S		Alias for -o gpsdrive.sql
	-a		For SQL, delete existing record only if it matches
			all fields.  Otherwise, delete it if it matches
			just the name and the type. 
	-D level	Debug level
	-U		Retrieve latest version of this script

COUNTRIES
	at, be, ca, dk, fr, de, it, lu, nl, es, ch, uk, us, fi, no, pt, se

EXAMPLES
	Geocode...

	    \$ geo-code "3049 Lake Shore Blvd" 55391
	    3049LakeShoreBlvd 44.94723 -93.49152 new

	    \$ geo-code -t house "3049 Lake Shore Blvd" "Wayzata, MN"
	    3049LakeShoreBlvd 44.94723 -93.49152 house

	    \$ geo-code -n "Bob's House" -t house "3049 Lake Shore Blvd" 55391
	    BobsHouse 44.94723 -93.49152 house

	    \$ geo-code -S -n "Bob" -t house "3049 Lake Shore Blvd" 55391
	    [waypoint is added to GpsDrive MySQL database]

	    \$ geo-code 952.476.8329
	    952.476.8329 44.94723 -93.49152 new

	    \$ geo-code "Schlossplatz 10" "76131 Karlsruhe" de
	    Schlossplatz10 49.01072 08.40557 new

SEE ALSO
	geo-nearest, geo-waypoint, geo-pg,

	http://www.rubygeocoder.com/

	https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?form

	$WEBHOME
EOF

	exit 1
}

#include "geo-common"

geocode_cloudmade() {
    KEY=a5122ce36b294ae8859eefa58364ca5e
    URL="http://geocoding.cloudmade.com/$KEY/geocoding/v2"
    #URL="$URL/find.plist?query=$address $city $state $zip"
    URL="$URL/find.plist?query=$address,$city,$state,$zip"
    #find.output_type?query=search_query&other_parameters
    URL=`echo "$URL" | tr ' ' '+' `
    debug 1 "curl -s $URL"
    curl $CURL_OPTS -A "$UA" -s "$URL" 
}

geocode_us_parse_db() {
    read lat lon title
    title=`echo "$title" |
	    sed -e 's/%2c/,/g' -e 's/[+]/ /g' -e 's/.*TI=//'`
}

geocode_us(){
    URL="http://geocoder.us/service/csv?"
    if [ "$address" == "" ]; then
	if [ "$city" != "" ]; then
	    URL="$URL&city=$city"
	fi
	if [ "$state" != "" ]; then
	    URL="$URL&state=$state"
	fi
	if [ "$zip" != "" ]; then
	    URL="$URL&zip=$zip"
	fi
	debug 1 "curl -s $URL"
	curl $CURL_OPTS -A "$UA" -s "$URL" | tail -1 >$COORDS
    else
	URL="$URL&address=$address,$city,$state,$zip"
	debug 1 "curl -s $URL"
	curl $CURL_OPTS -A "$UA" -s "$URL" | tail -1 >$COORDS
	# 44.978564,-93.309726,200 Queen Ave N,Minneapolis,MN,55405
    fi

    OIFS="$IFS";
    IFS=","; geocode_us_parse_db < $COORDS;
    IFS="$OIFS"
}

geocode_census_parse_db() {
    read lon lat
    title=`echo "$title" |
	    sed -e 's/%2c/,/g' -e 's/[+]/ /g' -e 's/.*TI=//'`
}

geocode_census(){
    URL="https://geocoding.geo.census.gov/geocoder/locations/onelineaddress"
    URL="$URL?benchmark=4"
    #URL="https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=3049+lake+shore+55391&benchmark=4"
    if [ "$address" == "" ]; then
	if [ "$city" != "" ]; then
	    URL="$URL&city=$city"
	fi
	if [ "$state" != "" ]; then
	    URL="$URL&state=$state"
	fi
	if [ "$zip" != "" ]; then
	    URL="$URL&zip=$zip"
	fi
	debug 1 "curl -s $URL"
	curl $CURL_OPTS -A "$UA" -s "$URL" | tail -1 >$COORDS
    else
	URL="$URL&address=$address+$city,$state,$zip"
	debug 1 "curl -s $URL"
	curl $CURL_OPTS -A "$UA" -s "$URL" |
	    grep "Coordinates:" |
	    sed -e "s/.*Coordinates:X: //" -e 's/Y: //' -e 's/<.*//' > $COORDS
	# 44.978564 -93.309726
    fi

    geocode_census_parse_db < $COORDS;
}

xyz_parse_db() {
    read lat lon
}

xyz(){
    URL="https://geocode.xyz/$address $zip $city $country"
    debug 1 "curl $URL"
    curl $CURL_OPTS -A "$UA" -s "$URL" |
	grep "<small>x,y z: <a href=" |
	sed -e "s/.*\///" -e "s/,/ /" -e 's/".*//' > $COORDS
    # <small>x,y z: <a href="https://geocode.xyz/49.01072,8.40557">

    xyz_parse_db < $COORDS;
}

#
#       Set default options, can be overriden on command line or in rc file
#
DEBUG=0
OUTFMT=gpsdrive
COUNTRY=us	# us, ca, fr, de, it,es, uk
SQLUSER=gast	# For -o gpsdrive.sql
SQLPASS=gast	# For -o gpsdrive.sql
SQLDB=geoinfo	# For -o gpsdrive.sql
CODETYPE=new
UPDATE_URL=$WEBHOME/geo-code
UPDATE_FILE=geo-code.new

read_rc_file

#
#       Process the options
#
ADDRESS=
CSZ=
MODE=babel
SQL=0
NAME=
GURL=
QUIET=0
SQLMATCH=type_name
while getopts "an:o:qSs:t:D:Uh?" opt
do
	case $opt in
	n)	NAME="$OPTARG";;
	o)	OUTFMT="$OPTARG";;
	s)	BABELFLAGS="$BABELFLAGS -s";;
	S)	OUTFMT="gpsdrive.sql";;
	t)	CODETYPE="$OPTARG";;
	q)	QUIET=1;;
	a)	SQLMATCH=all;;
	D)	DEBUG="$OPTARG";;
	U)	echo "Getting latest version of this script..."
		curl $CURL_OPTS -o$UPDATE_FILE "$UPDATE_URL"
		chmod +x "$UPDATE_FILE"
		echo "Latest version is in $UPDATE_FILE"
		exit
		;;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$OUTFMT" in
map)
	MODE=map
	MAPOPTS=
	;;
map,*)
	MODE=map
	MAPOPTS=`echo "$OUTFMT" | sed -n 's/map,\(.*\)$/\1/p'`
	;;
degdec)
	MODE=degdec
	;;
mindec)
	MODE=mindec
	;;
gpsdrive)
	BABELFLAGS=-s
	;;
gpsdrive.sql)
	BABELFLAGS=-s
	OUTFMT=gpsdrive
	MODE=sql
	# DEBUG=1
	;;
\?)
	gpsbabel -? | sed -e '1,/File Types/d' -e '/Supported data filters/,$d'
	echo	"	gpsdrive.sql         " \
		"GpsDrive direct MySQL database insertion"
	echo	"	degdec               " \
		"Just latitude and longitude, thank you"
	echo	"	mindec               " \
		"Just latitude and longitude, thank you"
	echo    "	map[,geo-map-opts]   " \
		"Display map of waypoints using geo-map"
	exit
	;;
esac

case "$#" in
3)
	#
	#	street_address citystate_or_zip country
	#
	ADDRESS=$1
	CSZ=$2
	COUNTRY=$3
	address=`urlencode2 "$ADDRESS"`
	csz="$CSZ"
	myname="$1, $2 $3"
	;;
2)
	#
	#	street-address citystate_or_zip
	#
	ADDRESS=$1
	CSZ=$2
	address=`urlencode2 "$ADDRESS"`
	csz="$CSZ"
	myname="$1, $2"
	;;
1)
	#
	# Reverse Phone Lookup
	#
	# phone number, including area code
	#
	PHONE=$1
	ADDRESS=$1
	TEL=`echo "$1" | tr -d -c 0-9 `
	REVTELURL="https://www.reversephonelookup.com/number/$TEL/"
	myname="$1"
	;;
*)
	usage
esac

country=`echo $COUNTRY | tr '[A-Z]' '[a-z]'`

#
#	procedure to make a gpsbabel style file
#
make_style() {
	cat <<-EOF
		FIELD_DELIMITER		TAB
		RECORD_DELIMITER	NEWLINE
		BADCHARS		TAB
		IFIELD	LAT_DECIMAL, "", "%.6f"
		IFIELD	LON_DECIMAL, "", "%.6f"
		IFIELD	DESCRIPTION, "", "%s"
		IFIELD	ICON_DESCR, "", "%s"
	EOF
}

#
#	Main Program
#
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

HTMLPAGE=${TMP}.html
STYLE=${TMP}.style
COORDS=${TMP}.coords
OUTWAY=${TMP}.way
CRUFT="$CRUFT $HTMLPAGE"
CRUFT="$CRUFT $STYLE"
CRUFT="$CRUFT $COORDS"
CRUFT="$CRUFT $OUTWAY"

case "$country" in
at|austri*)	region=0;;
be|bel*)	region=1;;
ca|can*)	region=2;;
dk|den*)	region=3;;
fr|fra*)	region=4;;
de|ger*)	region=5;;
it|ita*)	region=6;;
lu|lux*)	region=7;;
nl|net*)	region=8;;
es|spa*)	region=9;;
ch|swi*)	region=10;;
uk|bri*)	region=11;;
us|usa)		region=12;;
fi|fin*)	region=16;;
no|nor*)	region=17;;
pt|por*)	region=18;;
se|swe*)	region=19;;
*)		error "Unknown country '$country'";;
esac

if [ "$REVTELURL" != "" ]; then
    #
    # Treat a single command line argument as a phone number and use
    # www.reversephonelookup.com to look up the address
    #	
    debug 1 "curl $REVTELURL"
    curl $CURL_OPTS -s -A "$UA" "$REVTELURL" |
	grep -A1 Address: | tail -1 > $HTMLPAGE
    address=`sed -e 's/^<[^>]*>//' -e 's/<.*//' < $HTMLPAGE`
    city=`sed -e 's/.*<br>//' -e 's/,.*//' < $HTMLPAGE`
    state=`sed -e 's/.*, //' -e 's/<.*//' -e 's/ [0-9]\{5\}$//' < $HTMLPAGE`
    zip=`sed -e 's/.* //' -e 's/<.*//' < $HTMLPAGE`

    if [ "$address" = "" ]; then
	error "Unable to lookup telephone number with reversephonelookup.com"
    fi
else
    city=
    state=
    zip=
    case "$region" in
    2)	# Canada
	case "$csz" in
	[A-Z][0-9][A-Z]\ [0-9][A-Z][0-9])
	    zip="$csz"
	    ;;
	*,*\ [A-Z][0-9][A-Z]\ [0-9][A-Z][0-9])
	    city=`echo "$csz" | sed 's/,.*//'`
	    state=`echo "$csz" | sed -e 's/.*, *//' -e 's/ \+... \+...$//' `
	    zip=`echo "$csz" | sed -e 's/^.* \(... \+...\)$/\1/' `
	    ;;
	*,*)
	    city=`echo "$csz" | sed 's/,.*//'`
	    state=`echo "$csz" | sed 's/.*, *//'`
	    ;;
	*)
	    error "Unable to parse '$csz' into city, state zip"
	    ;;
	esac
	;;
    12) # US
	#
	# Parse CSZ into C, S, Z for MapPoint
	#
	case "$csz" in
	[0-9][0-9][0-9][0-9][0-9])
	    zip="$csz"
	    ;;
	[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9])
	    zip="$csz"
	    ;;
	*,*\ [0-9][0-9][0-9][0-9][0-9])
	    city=`echo "$csz" | sed 's/,.*//'`
	    state=`echo "$csz" | sed -e 's/.*, *//' -e 's/ \+[0-9-]\+//' `
	    zip=`echo "$csz" | sed -e 's/^.* \+//' `
	    ;;
	*,*\ [0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9])
	    city=`echo "$csz" | sed 's/,.*//'`
	    state=`echo "$csz" | sed -e 's/.*, *//' -e 's/ \+[0-9-]\+//' `
	    zip=`echo "$csz" | sed -e 's/^.* \+//' `
	    ;;
	*,*)
	    city=`echo "$csz" | sed 's/,.*//'`
	    state=`echo "$csz" | sed 's/.*, *//'`
	    ;;
	*)
	    error "Unable to parse '$csz' into city, state zip"
	    ;;
	esac
	;;
    *)
	case "$csz" in
	*\ *)
	    city=`echo "$csz" | sed 's/^[^ ]\+ \+//'`
	    zip=`echo "$csz" | sed 's/ \+.*//'`
	    ;;
	*)
	    zip="$csv"
	    ;;
	esac
	;;
    esac
fi

debug 1 "address=<$address> city=<$city> state=<$state> zip=<$zip>"
debug 1 "myname=<$myname>"
debug 1 "country=<$country> region=<$region>"

# Determine lat, lon, and title
case "$region" in
12)	geocode_census;;
#12)	geocode_us;;
#12)	geocode_cloudmade;;
*)	xyz;;
esac

if [ "$title" != ""  -a "$QUIET" != 1 ]; then
	echo "$title" >&2
fi
if [ "$lat" = "" -o "$lon" = "" ]; then
	error "Cannot determine coordinates of that address"
fi

latM=`degdec2mindec $lat`
lonM=`degdec2mindec $lon`

case "$MODE" in
map)
	echo "$lat	$lon"
	geo-map -D$DEBUG $MAPOPTS $lat $lon "$myname"
	exit
	;;
degdec)
	echo "$lat	$lon"
	exit
	;;
mindec)
	echo "$latM	$lonM"
	exit
	;;
esac

if [ "$NAME" = "" ]; then
	if [ "$ADDRESS" = "" ]; then
	    NAME="$CSZ"
	else
	    NAME="$ADDRESS"
	fi
else
    #
    #	Expand % escapes in name to lat/lon, address, etc.
    #
    case "$NAME" in
    *%m*) NAME=`echo "$NAME" | sed "s/%m/$latM/g" `;;
    esac
    case "$NAME" in
    *%M*) NAME=`echo "$NAME" | sed "s/%M/$lonM/g" `;;
    esac
    case "$NAME" in
    *%d*) NAME=`echo "$NAME" | sed "s/%d/$lat/g" `;;
    esac
    case "$NAME" in
    *%D*) NAME=`echo "$NAME" | sed "s/%D/$lon/g" `;;
    esac
    case "$NAME" in
    *%a*) NAME=`echo "$NAME" | sed "s/%a/$ADDRESS/g" `;;
    esac
    case "$NAME" in
    *%c*) NAME=`echo "$NAME" | sed "s/%a/$CSZ/g" `;;
    esac
    case "$NAME" in
    *%p*) NAME=`echo "$NAME" | sed "s/%p/$PHONE/g" `;;
    esac
    case "$NAME" in
    *%%*) NAME=`echo "$NAME" | sed "s/%%/%/g" `;;
    esac
fi

make_style > $STYLE

echo "$lat	$lon	$NAME	$CODETYPE" > $COORDS
gpsbabel $BABELFLAGS -i xcsv,style=$STYLE -f $COORDS -o "$OUTFMT" -F $OUTWAY

#
#	Output the data or add it to the MySQL database
#
gpsdrive_add() {
	delcmd="delete from waypoints"
	addcmd="insert into waypoints (name,lat,lon,type,comment)"

	read _name _lat _lon _type

	COMMENT="$ADDRESS"
	if [ "$CSZ" != "" ]; then
		COMMENT="$COMMENT, $CSZ"
	fi

	echo "use $SQLDB;"
	case "$SQLMATCH" in
	all)
		# Must be a complete match to delete existing record
		echo "$delcmd where name='$_name' and type='$_type'"
		echo "and lat='$_lat' and lon='$_lon';"
		;;
	*)
		# Must match only name and type
		echo "$delcmd where name='$_name' and type='$_type';"
		;;
	esac
	echo "$addcmd values ('$_name','$_lat','$_lon','$_type',"
	echo "'$COMMENT');"
}

if [ -f $OUTWAY ]; then
	case "$MODE" in
	sql)
		#
		# add it via mysql
		#
		if [ $QUIET != 1 ]; then
			echo "$NAME $lat $lon $CODETYPE" >&2
		fi
		if [ $DEBUG -gt 0 ]; then
			gpsdrive_add <$OUTWAY
		else
			gpsdrive_add <$OUTWAY | mysql -u$SQLUSER -p$SQLPASS
		fi
		;;
	*)
		#
		# output to stdout
		#
		cat $OUTWAY
		;;
	esac
fi

exit 0
