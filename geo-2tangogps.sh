#!/bin/bash

#
#	geo-2tangogps: Enter a waypoint file into the GpsDrive SQL database
#
#	Requires: sglite3 (if using the tangogps.sql output option)
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-2tangogps.sh,v 1.10 2013/02/18 21:41:05 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Enter a file of waypoints into the tangogps SQL database.

SYNOPSIS
	`basename $PROGNAME` [options] waypoint-file
	`basename $PROGNAME` [options] waypoint-file latitude longitude

DESCRIPTION
	Enter a file of waypoints into the tangogps or FoxtrotGPS SQL database.

	This is useful if you have a file of waypoints from geo-nearest
	that you need to convert into tangogps format plus one or more
	other formats, such as Cetus plus tangogps.  Gpsbabel currently
	doesn't know how to enter waypoints directly into an SQL database
	(and its not clear to me whether it should be taught how to do
	this or not).

OPTIONS
	-s		Output short names for the caches (gpsbabel option)
	-r radius	Display only caches with radius (e.g. -r 25M)

	-f		Use FoxtrotGPS instead of tangoGPS for the DB file.
			Right now, just changes SQLDB to ~/.foxtrotgps/poi.db
	-i format	Input format, -o? for possibilities [$INFMT]
	-S              Enter waypoints into SQL database
        -d              For -S, just delete selected records
        -P              For -S, purge all records of type -t $SQLTAG*
	-t type		The waypoint type [$SQLTAG]
        -X term         Exclude caches with 'term' [$EXCLUDE]
	-D lvl		Debug level [$DEBUG]
	-U		Retrieve latest version of this script

	Defaults can also be set with variables in file \$HOME/.georc:

	    LAT=latitude;       LON=logitude;
	    OUTFMT=format;      BABELFLAGS=-s;
	    SQLUSER=gast;       SQLPASS=gast;        SQLDB=~/.tangogps/poi.db
;

EXAMPLES
	Display shortnames:

	    geo-2tangogps -s caches.tabsep

	Add caches to a tangogps SQL database

	    geo-2tangogps -s -S caches.tabsep

	Purge the existing SQL database of all geocaches, then enter new ones:

	    geo-2tangogps -S -P -s caches.tabsep

SEE ALSO
	geo-newest, geo-found, geo-placed, geo-nearest,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-tangogps"

#
#       Set default options, can be overriden on command line or in rc file
#
DEBUG=0
INFMT=tabsep
BABELFLAGS=

read_rc_file

#
#       Process the options
#
PURGE=0
DELETE=0
SQL=0
while getopts "dfi:Pr:sSt:X:D:h?" opt
do
	case $opt in
	d)	DELETE=1;;
	P)	PURGE=1;;
	f)	SQLDB=$HOME/.foxtrotgps/poi.db;;
	i)	INFMT="$OPTARG";;
	r)	RADIUS="$OPTARG";;
	s)	BABELFLAGS="$BABELFLAGS -s";;
	S)      SQL=1;;
	t)	SQLTAG="$OPTARG";;
	X)
                if [ "" = "$OPTARG" -o "~"  = "$OPTARG" ]; then
                    EXCLUDE=-ExClUdEnOtHiNg
                else
                    EXCLUDE="$OPTARG"
                fi
		;;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
case "$#" in
1)	INFILE="$1";;
*)	usage;;
esac

OUTFMT=gpsdrive
OUTFMT=tabsep
OUTFILE=
BABELFILT=
if [ "$RADIUS" != "" ]; then
    BABELFILT="-x radius,distance=$RADIUS,lat=$LAT,lon=$LON"
fi

if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

if [ $SQL = 1 ]; then
	#
	# add it via sglite3
	#
	if [ "$OUTFILE" != "" ]; then
	    >"$OUTFILE"
	fi

	if [ $PURGE = 1 ]; then
	    tangogps_purge | tangogps_sqlite3
	    PURGE=2
	fi

	OUTTMP="$TMP.way";  CRUFT="$CRUFT $OUTTMP"
	dbgcmd gpsbabel $BABELFLAGS \
	    -i $INFMT -f $INFILE \
	    $BABELFILT -o "$OUTFMT" -F $OUTTMP
	tangogps_add <$OUTTMP $SQLTAG | tangogps_sqlite3
else
	#
	# output to stdout or to a file
	#
	if [ "$OUTFILE" = "" ]; then
	    OUTTMP="$TMP.way";  CRUFT="$CRUFT $OUTTMP"
	    dbgcmd gpsbabel $BABELFLAGS \
		-i $INFMT -f $INFILE \
		$BABELFILT -o "$OUTFMT" -F $OUTTMP
	    cat $OUTTMP
	else
	    dbgcmd gpsbabel $BABELFLAGS \
		-i $INFMT -f $INFILE \
		$BABELFILT -o "$OUTFMT" -F $OUTFILE
	fi
fi
