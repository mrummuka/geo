#!/bin/bash

#
#	geo-nearest: Fetch list of nearest geocaches.
#
#	Requires: curl; gpsbabel; bash or ksh;
#		  mysql (if using the gpsdrive.sql output option)
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-nearest.sh,v 1.54 2018/04/26 16:14:09 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Fetch a list of nearest geocaches

SYNOPSIS
    `basename $PROGNAME` [options]

    `basename $PROGNAME` [options] latitude longitude

    `basename $PROGNAME` [options] latitude longitude cache-type

    `basename $PROGNAME` [options] zipcode

    `basename $PROGNAME` [options] u=<username>

    `basename $PROGNAME` [options] ul=<username>

    `basename $PROGNAME` [options] pq=<pocket-query>

    `basename $PROGNAME` [options] tx=<bookmark-id>

    `basename $PROGNAME` [options] -b bookmark
    `basename $PROGNAME` [options] guid=<bookmark-id>

DESCRIPTION
    Fetch a list of nearest geocaches.

    Requires:
        A premium member (\$30/yr) OR a basic member (free) login at:
             http://www.geocaching.com
        Visit a cache page and click the "Download to EasyGPS" link at least
        once so you can read and agree to the license terms.  Otherwise, you
        will not get any waypoint data.

	curl		http://curl.haxx.se/
	gpsbabel	http://gpsbabel.sourceforge.net/

EOF
	gc_usage
	cat << EOF

NOTE
    A basic member will get caches very slow (20 cache pages per minute)
    because we have to get the actual cache pages.  They will be stored in:
        ~/.geo/caches/GCXXXX.html.
    Of course, after running this command, geo-html2gpx could be run.

EXAMPLES
    Nearest 20 caches, display shortnames:

	geo-nearest -s

    Search nearest 500 caches for virtual caches not yet found:

	geo-nearest -n500 -Ivirtual -Xifound

    Nearest 20 with unavailable (disabled) caches:

	geo-nearest -X~

    Add nearest 50 caches to a GpsDrive SQL database

	geo-nearest -n50 -f -s -S

    Purge the existing SQL database of all geocaches, and fetch
    200 fresh ones...

	geo-nearest -S -P -s -n200

    640x480 map of nearest caches using map source 2:

	geo-nearest -omap,"-a2 -W640 -H480"

    Copy two cachers:

	geo-nearest -n200 -Xifound -udyl1231 -pPW | awk '{print \$1}' >1.foo
	geo-nearest -n200 -Xifound -urickrich -pPW |awk '{print \$1}' >2.foo
	geo-gid -otabsep \$(comm -12 1.foo 2.foo) >both

    Fetch by owner placed:

	geo-nearest u=team-deadhead

    Fetch by owner found:

	geo-nearest ul="AAA+of+MichigAn&sortdir=asc&sort=placed"

    Fetch by tx method:

	# nearby caches of this (puzzle) type, that I haven't found
	geo-nearest -n500 -f -otabsep tx=40861821-1835-4e11-b666-8d41064d03fe |
	    geo-mystery >> Caches/rick.ts

	Also, tx=webcam, tx=earth, tx=multi, tx=event, tx=virtual, tx=letter,
	tx=unknown, tx=trad (tx=reg is an alias).

    Fetch by cache-type method:

	# nearby puzzles, that I haven't found from my HOME lat/lon
	geo-nearest -n500 -f -otabsep '\$LAT' '\$LON' unknown |
	    geo-mystery >> Caches/rick.ts

	Also, cache-type is webcam, earth, multi, event, virtual, letter,
	unknown, trad (reg is an alias).

    Fetch a bookmark list:

	geo-nearest -b acro
	or
	geo-nearest -b BM52955
	or
	geo-nearest guid=baae5bf9-4315-4874-b7fb-ac84c9585641

    Fetch a PQ query:

	geo-nearest -q "Needs Maintenance"
	or
	geo-nearest pq=08be103b-ffd1-4e27-992f-616e144e24df

FILES
    ~/.georc
    ~/.geo/caches/

SEE ALSO
    geo-newest, geo-found, geo-placed, geo-keyword, geo-code, geo-map,
    geo-waypoint,
    $WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/geo-nearest
UPDATE_FILE=geo-nearest.new

read_rc_file

#
#       Process the options
#

gc_getopts "$@"
shift $?

#
#	Main Program
#
case "$#" in
6)
	# Cut and paste from geocaching.com cache page
	# N 44° 58.630 W 093° 09.310
	LAT=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT=`latlon $LAT`
	LON=`echo "$4$5.$6" | tr -d '\260\302' `
	LON=`latlon $LON`
	SEARCH="?origin_lat=$LAT&origin_long=$LON"
	;;
3)
	# lat lon cache-type
	eval LAT=`latlon $1`
	eval LON=`latlon $2`
	case "$3" in
	webcam)		cFilter="31d2ae3c-c358-4b5f-8dcd-2185bf472d3d";;
	earth*)		cFilter="c66f5cf3-9523-4549-b8dd-759cd2f18db8";;
	multi*)		cFilter="a5f6d0ad-d2f2-4011-8c14-940a9ebf3c74";;
	event)		cFilter="69eb8534-b718-4b35-ae3c-a856a55b0874";;
	virtual)	cFilter="294d4360-ac86-4c83-84dd-8113ef678d7e";;
	letter*)	cFilter="4bdd8fb2-d7bc-453f-a9c5-968563b15d24";;
	unknown)	cFilter="40861821-1835-4e11-b666-8d41064d03fe";;
	trad*)		cFilter="32bc9333-5e52-4957-b0f6-5a2c8fc7b257";;
	reg*)		cFilter="32bc9333-5e52-4957-b0f6-5a2c8fc7b257";;
	*)		error "Unknown cache-type '$3'";;
	esac
	SEARCH="?lat=$LAT&lng=$LON&cFilter=$cFilter"
	;;
2)
	LAT=`latlon $1`
	LON=`latlon $2`
	SEARCH="?origin_lat=$LAT&origin_long=$LON"
	;;
1)
	case "$1" in
	iraq|Iraq) SEARCH="?country_id=97" ;;
	u=*)
	    SEARCH="?$1"
	    ;;
	ul=*)
	    SEARCH="?$1"
	    ;;
	pq=*)
	    SEARCH="?$1"
	    ;;
	tx=*\&*)
	    # tx=NNN&ul=USERNAME
	    SEARCH="?$1"
	    ;;
	tx=*)
	    LAT=`latlon $LAT`
	    LON=`latlon $LON`
	    case "$1" in
	    tx=webcam)	tx="tx=31d2ae3c-c358-4b5f-8dcd-2185bf472d3d";;
	    tx=earth*)	tx="tx=c66f5cf3-9523-4549-b8dd-759cd2f18db8";;
	    tx=multi*)	tx="tx=a5f6d0ad-d2f2-4011-8c14-940a9ebf3c74";;
	    tx=event)	tx="tx=69eb8534-b718-4b35-ae3c-a856a55b0874";;
	    tx=virtual)	tx="tx=294d4360-ac86-4c83-84dd-8113ef678d7e";;
	    tx=letter*)	tx="tx=4bdd8fb2-d7bc-453f-a9c5-968563b15d24";;
	    tx=unknown)	tx="tx=40861821-1835-4e11-b666-8d41064d03fe";;
	    tx=trad*)	tx="tx=32bc9333-5e52-4957-b0f6-5a2c8fc7b257";;
	    tx=reg*)	tx="tx=32bc9333-5e52-4957-b0f6-5a2c8fc7b257";;
	    *)		tx=$1;;
	    esac
	    SEARCH="?$tx&lat=$LAT&lng=$LON"
	    ;;
	guid=*)
	    SEARCH="bookmarks/view.aspx?$1"
	    ;;
	*[0-9]*)
	    ZIP=$1
	    SEARCH="?zip=$ZIP"
	    ;;
	*)
	    error "'$1' isn't something I understand how to search for"
	    ;;
	esac
	;;
0)
	SEARCH="?origin_lat=$LAT&origin_long=$LON"
	;;
*)
	usage
	;;
esac

gc_query
