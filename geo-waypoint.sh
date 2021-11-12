#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-waypoint.sh,v 1.20 2013/02/18 21:41:07 rick Exp $
#

PROGNAME="$0"
WEBHOME="http://geo.rkkda.com/"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Convert a lat/lon into a waypoint using gpsbabel

SYNOPSIS
	`basename $PROGNAME` [options] latitude longitude name

DESCRIPTION
	Convert a latitude/longitude into a waypoint using gpsbabel.
	Lat/Lon may be in DegDec, MinDec, or DMS formats.

	Acceptable formats for lat/lon are:

		-93.49130	DegDec (decimal degrees)
		W93.49130	DegDec (decimal degrees)

		"-93 29.478"	MinDec (decimal minutes)
		"W93 29.478"	MinDec (decimal minutes)
		-93.29.478	MinDec (decimal minutes)
		W93.29.478	MinDec (decimal minutes)
		
		"-93 45 30"	DMS (degrees, minutes, seconds)

OPTIONS
	-o format	Output format, -o? for possibilities [$OUTFMT]
			plus "gpsdrive.sql" for direct insertion into MySQL DB
	-S              Alias for -o gpsdrive.sql
        -d              For -S, just delete selected records
	-t type		The waypoint type [$SQLTAG]
	-V gpsver	Version of gpsdrive (2.09 or 2.10+) [$GPSDRIVE_VER]
	-D lvl		Debug level [$DEBUG]
	-U		Retrieve latest version of this script

	Defaults can also be set with variables in file \$HOME/.georc:

		NUM=num;            OUTFMT=format;       BABELFLAGS=-s;
		SQLUSER=gast;       SQLPASS=gast;        SQLDB=geoinfo;

EXAMPLES
	Enter a lat/lon into the GpsDrive 2.09 waypoint SQL database:

	    geo-waypoint -S "45 50.501" "-93 23.609" MultiCacheLeg2

	Enter a lat/lon into the GpsDrive 2.11 waypoint SQL database:

	    geo-waypoint -V 2.11 -S "45 50.501" "-93 23.609" MultiCacheLeg2

SEE ALSO
	geo-code, geo-pg, geo-nearest,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
DEBUG=0
ZIP=
OUTFMT=gpsdrive
BABELFLAGS=-s
GPSDRIVE_VER=2.09
UPDATE_URL=$WEBHOME/geo-waypoint
UPDATE_FILE=geo-waypoint.new
NOFOUND=0

read_rc_file

#
#       Process the options
#
PURGE=0
DELETE=0
SQL=0
while getopts "do:sSt:D:UV:h?-" opt
do
	case $opt in
	d)	DELETE=1;;
	s)	BABELFLAGS="$BABELFLAGS -s";;
	S)      OUTFMT="gpsdrive.sql";;
	t)	SQLTAG="$OPTARG";;
	o)	OUTFMT="$OPTARG";;
	V)	GPSDRIVE_VER="$OPTARG";;
	D)	DEBUG="$OPTARG";;
	U)	echo "Getting latest version of this script..."
		curl $CURL_OPTS -o$UPDATE_FILE "$UPDATE_URL"
		chmod +x "$UPDATE_FILE"
		echo "Latest version is in $UPDATE_FILE"
		exit
		;;
	h|\?|-)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$OUTFMT" in
gpsdrive.sql)
	case "$GPSDRIVE_VER" in
	2.09)
		OUTFMT=gpsdrive
		;;
	2.[1-9]*)
		GPSDRIVE_VER=2.10
		OUTFMT=tabsep
		;;
	*)
		error "Only versions of gpsdrive: 2.09 OR 2.10+"
		;;
	esac
	SQL=1
	# DEBUG=1
	;;
\?)
	gpsbabel -? | sed '1,/File Types/d'
	echo	"	gpsdrive.sql         " \
		"GpsDrive direct MySQL database insertion"
	exit
	;;
esac

if [ $# -lt 3 ]; then
	usage
fi

case "$1" in
N|S)
    if [ $# -gt 6 ]; then
	# Cut and paste from geocaching.com cache page
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

NAME="$*"

#
#	Main Program
#

if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

GEOWAY=${TMP}.geocaching.loc
OUTWAY=${TMP}.way
CRUFT="$CRUFT $GEOWAY"
CRUFT="$CRUFT $OUTWAY"

#
#	We might combine one or more pages into a single XML, so cobble
#	up a header with the ?xml and loc tags.
#	
cat <<-EOF > $GEOWAY
	<?xml version="1.0" encoding="UTF-8"?>
	<loc version="1.0" src="EasyGPS">
	<waypoint><name id="XXXXX"><![CDATA[$NAME]]></name>
	<coord lat="$LAT" lon="$LON"/>
	<type>$SQLTAG</type>
	</waypoint>
	</loc>
EOF

#
# Convert to desired format
#
if [ $DEBUG -gt 0 ]; then
	cp $GEOWAY /tmp/geocaching.loc
fi

gpsbabel $BABELFLAGS -i geo$GEONUKE -f $GEOWAY -o "$OUTFMT" -F $OUTWAY

if [ -f $OUTWAY ]; then
	if [ $SQL = 1 ]; then
		#
		# add it via mysql
		#
		if [ $DEBUG -gt 0 ]; then
			gpsdrive_add $SQLTAG <$OUTWAY
		else
		    case "$GPSDRIVE_VER" in
		    2.09)   gpsdrive_add <$OUTWAY $SQLTAG | gpsdrive_mysql;;
		    2.10)   gpsdrive_add <$OUTWAY $SQLTAG | gpsdrive_sqlite3;;
		    esac
		fi
	elif [ $DELETE = 0 ]; then
		#
		# output to stdout
		#
		cat $OUTWAY
	fi
fi
