#!/bin/bash

#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-gpx.sh,v 1.38 2018/11/09 14:44:01 rick Exp $

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch GPX file(s) by gc.com waypoint name

SYNOPSIS
	`basename $PROGNAME` [options] gid ...

DESCRIPTION
	Fetch GPX file(s) by gc.com waypoint name (i.e. GCxxxx)

	If no output format is specified, the GPX data is stored into
	individual files named <gid>.gpx.

	If an output format is specified with -o, the GPX data is combined
	into a single file with that format and output into stdout or to
	the filename specified with the -O option.

	Requires: A subscriber login at http://www.geocaching.com.

EOF
	# gc_usage
	cat << EOF
OPTIONS
	-o format	Output format, -o? for possibilities [$OUTFMT]
			plus "gpsdrive.sql" for direct insertion into MySQL DB
			plus "map[,geo-map-opts]" to display a geo-map.
	-O filename	Output file, if not stdout
	-u username	Username for http://www.geocaching.com
	-p password	Password for http://www.geocaching.com
	-D lvl		Debug level [$DEBUG]
	-U		Retrieve latest version of this script

	Defaults can also be set with variables in file \$HOME/.georc:

	    PASSWORD=password;  USERNAME=username;

EXAMPLES
	Get a gc.com style gpx file for a single cache...

	    geo-gpx GC3T7TK

	Get a gc.com style gpx file for the 20 newest caches...

	    geo-gpx -ogpx -Onewest.gpx \$(geo-newest | awk '{print \$1}')

SEE ALSO
	geo-gid, geo-newest, geo-found, geo-placed, geo-nearest,
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
UPDATE_URL=$WEBHOME/geo-gpx
UPDATE_FILE=geo-gpx.new

read_rc_file

#
#       Process the options
#
OUTFMT=
OUTFILE=-
gc_getopts "$@"
shift $?

if [ $# = 0 ]; then
    usage
fi

#
#	Main program
#
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

HTMLPAGE=$TMP.page
CRUFT="$CRUFT $HTMLPAGE"
GPXPAGE=$TMP.gpx
CRUFT="$CRUFT $GPXPAGE"
if [ $NOCOOKIES = 1 ]; then
    CRUFT="$CRUFT $COOKIE_FILE"
fi

#
#	Get the GPX data for a single waypoint and output it on stdout
#
get1gpx() {
    _gid=$1
    #
    # get the HTML cache page to get us the proper viewstate for this cache.
    # i.e.
    #	http://www.geocaching.com/seek/cache_details.aspx?wp=GC3T7TK
    #
    # this page fetch is wasteful, but I know no other way to get it.
    #
    URL="$GEO/seek/cache_details.aspx"
    URL="$URL?wp=$_gid"
    dbgcmd curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" "$URL" \
	-w "%{url_effective}\n" \
	-o /dev/null > $HTMLPAGE

    #
    # Get the redirected page, i.e.
    #	https://www.geocaching.com/seek/cache_details.aspx?wp=GC18438&title=achterwehr
    #
    URL=`cat $HTMLPAGE`
    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -A "$UA" "$URL" \
	> $HTMLPAGE

    gc_getviewstate $HTMLPAGE

    #
    # now fetch the GPX file
    #
    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -A "$UA" \
	    $viewstate \
	    -d __EVENTTARGET=ctl00\$ContentBody\$lnkGpxDownload \
	    "$URL"
    # Bug in bash 4.0.23
    # echo -e "\r\n"
    printf "\r\n"
}

#
#	check to see if there is an error in the GPX file
#
check_gpx() {
    case `file $1` in
    *XML*)	;;
    *HTML*)
	# GPXPAGE=~/tmp/geo.gpx
	if grep -s -q "^<html xmlns" $1; then
	    lynx -dump -stdin < $1 | sed '/^$/d'
	    error "Error is listed above!"
	elif grep -s -q "<h2>Cache is Unpublished</h2>" $1; then
	    error "Cache is Unpublished"
	else
	    error "Have to be a subscriber!"
	fi
    esac
}

#
#	Login to gc.com
#
gc_login "$USERNAME" "$PASSWORD"

if [ "$OUTFMT" = "" ]; then
    for gid in $*; do
	get1gpx $gid > $GPXPAGE
	check_gpx $GPXPAGE
	dos2unix <$GPXPAGE > $gid.gpx
    done
else
    i=1
    state=$#
    for gid in $*; do
	case "$state" in
	1)  # No need to strip anything
	    get1gpx $gid
	    ;;
	0)  # strip leading xml/gpx info, and maybe trailing too
	    sleep $GEOSLEEP
	    if ((i != $#)); then
		get1gpx $gid \
		| sed -e '1,/<bounds /d' -e '/^<\/gpx>/d'
	    else
		get1gpx $gid \
		| sed '1,/<bounds /d'
	    fi
	    ;;
	*)  # strip trailing /gpx tag
	    state=0
	    get1gpx $gid \
	    | sed '/^<\/gpx>/d'
	    ;;
	esac
	((++i))
    done | dos2unix > $GPXPAGE

    check_gpx $GPXPAGE

    gpsbabel -i gpx -f "$GPXPAGE" -o "$OUTFMT" -F "$OUTFILE"
fi
