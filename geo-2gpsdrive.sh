#!/bin/bash

#
#	geo-2gpsdrive: Enter a waypoint file into the GpsDrive SQL database
#
#	Requires: mysql (if using the gpsdrive.sql output option)
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-2gpsdrive.sh,v 1.20 2013/02/18 21:41:05 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Enter a file of waypoints into the GpsDrive SQL database.

SYNOPSIS
	`basename $PROGNAME` [options] waypoint-file
	`basename $PROGNAME` [options] waypoint-file latitude longitude

DESCRIPTION
	Enter a file of waypoints into the GpsDrive SQL database (if
	version of gpsdrive is 2.09 or less) OR sqlite3 database (if
	version of gpsdrive is 2.10 or greater).

	This is useful if you have a file of waypoints from geo-nearest
	that you need to convert into Gpsdrive format plus one or more
	other formats, such as Cetus plus GpsDrive.  Gpsbabel currently
	doesn't know how to enter waypoints directly into an SQL database
	(and its not clear to me whether it should be taught how to do
	this or not).

OPTIONS
	-s		Output short names for the caches (gpsbabel option)
	-r radius	Display only caches with radius (e.g. -r 25M)

	-i format	Input format, -o? for possibilities [$INFMT]
	-S              Enter waypoints into SQL database
        -d              For -S, just delete selected records
        -P              For -S, purge all records of type -t $SQLTAG*
	-t type		The waypoint type [$SQLTAG]
	-V gpsver	Version of gpsdrive (2.09 or 2.10+) [$GPSDRIVE_VER]
	-D lvl		Debug level [$DEBUG]
	-U		Retrieve latest version of this script

	Defaults can also be set with variables in file \$HOME/.georc:

	    LAT=latitude;       LON=logitude;
	    OUTFMT=format;      BABELFLAGS=-s;
	    SQLUSER=gast;       SQLPASS=gast;        SQLDB=geoinfo;

EXAMPLES
	Display shortnames:

	    geo-2gpsdrive -s caches.tabsep

	Add caches to a GpsDrive SQL database

	    geo-2gpsdrive -s -S caches.tabsep

	Purge the existing SQL database of all geocaches, then enter new ones:

	    geo-2gpsdrive -S -P -s caches.tabsep

SEE ALSO
	geo-newest, geo-found, geo-placed, geo-nearest,
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
INFMT=tabsep
BABELFLAGS=
GPSDRIVE_VER=2.09

read_rc_file

#
#       Process the options
#
PURGE=0
DELETE=0
SQL=0
while getopts "di:Pr:sSt:V:D:h?" opt
do
	case $opt in
	d)	DELETE=1;;
	P)	PURGE=1;;
	i)	INFMT="$OPTARG";;
	r)	RADIUS="$OPTARG";;
	s)	BABELFLAGS="$BABELFLAGS -s";;
	S)      SQL=1;;
	t)	SQLTAG="$OPTARG";;
	V)	GPSDRIVE_VER="$OPTARG";;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

#
#	Main Program
#
case "$#" in
1)	INFILE="$1";;
*)	usage;;
esac

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
OUTFILE=
BABELFILT=
if [ "$RADIUS" != "" ]; then
    BABELFILT="-x radius,distance=$RADIUS,lat=$LAT,lon=$LON"
fi

if [ $SQL = 1 ]; then
	#
	# add it via mysql OR sqlite3
	#
	if [ "$OUTFILE" != "" ]; then
	    >"$OUTFILE"
	fi

	if [ $PURGE = 1 ]; then
	    case "$GPSDRIVE_VER" in
	    2.09)	gpsdrive_purge | gpsdrive_mysql;;
	    2.10)	gpsdrive_purge | gpsdrive_sqlite3;;
	    esac
	    PURGE=2
	fi

	OUTTMP="$TMP.way";  CRUFT="$CRUFT $OUTTMP"
	dbgcmd gpsbabel $BABELFLAGS \
	    -i $INFMT -f $INFILE \
	    $BABELFILT -o "$OUTFMT" -F $OUTTMP
	case "$GPSDRIVE_VER" in
	2.09)	gpsdrive_add <$OUTTMP $SQLTAG | gpsdrive_mysql;;
	2.10)	gpsdrive_add <$OUTTMP $SQLTAG | gpsdrive_sqlite3;;
	esac
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
