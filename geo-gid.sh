#!/bin/bash

#
#	HACK ALERT!  This was quickly hacked from an existing script,
#	and needs to be merged back into the main codebase.
#

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-gid.sh,v 1.38 2018/07/08 16:12:12 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Fetch data about geocaches by gc.com GID

SYNOPSIS
    `basename $PROGNAME` [options] gid ...

DESCRIPTION
    Fetch data about geocaches by gc.com GID.  Only works with caches that
    are active (not archived).

    Requires:
        A subscriber ($30/yr) login at http://www.geocaching.com.  Visit a
        cache page and click the "Download to EasyGPS" link at least once so
        you can read and agree to the license terms.  Otherwise, you will not
        get any waypoint data.

	curl		http://curl.haxx.se/
	gpsbabel	http://gpsbabel.sourceforge.net/

OPTIONS
        -c              Remove cookie file when done
        -f              Do not report any found or unavailable caches
        -m              Do not report any members-only caches
        -F              Report caches found by the login 'username' as unfound
        -s              Output short names for the caches (gpsbabel option)
        -u username     Username for http://www.geocaching.com
        -p password     Password for http://www.geocaching.com
        -o format       Output format, -o? for possibilities [gpsdrive]
                        plus "gpsdrive.sql" for direct insertion into MySQL DB
                        plus "map[,geo-map-opts]" to display a geo-map.
        -O filename     Output file, if not stdout
        -S              Alias for -o gpsdrive.sql
        -d              For -S, just delete selected records
        -P              For -S, purge all records of type -t Geocache*
        -t type         For -ogpsdrive.sql, the waypoint type [Geocache]
        -H htmldir      Also fetch the printable HTML pages (slowly)
        -L logdir       Also fetch the plain text log entries (slowly)
                        For -H or -L, the limit is 1500 updated caches/day.
        -! "lpr -Plp"   Print HTML pages
        -D lvl          Debug level [0]
        -U              Retrieve latest version of this script

DEFAULTS
        Defaults can also be set with variables in file $HOME/.georc:

            PASSWORD=password;  USERNAME=username;   SOC=0|1;
            LAT=latitude;       LON=logitude;        GEOMYSTERY=/dev/null;
            NUM=num;            OUTFMT=format;       BABELFLAGS=-s;
            SQLUSER=gast;       SQLPASS=gast;        SQLDB=geoinfo;

EXAMPLES
    geo-gid GC4TAX4

SEE ALSO
    geo-newest, geo-found, geo-placed, geo-nearest,
    $WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"
#include "geo-common-gpsdrive"

gid2id() {
    gid="${1/#GC/}"
    ((val=0))
    ((pos=0))
    case "$gid" in
    ?????)
	while ((pos < 5)); do
	    digit=`expr index 0123456789ABCDEFGHJKMNPQRTVWXYZ "${gid:$pos:1}"`
	    ((val=val*31+$digit-1))
	    ((++pos))
	done
	;;
    *)
	if [ "$gid" "<" "G000" ]; then
	    echo "$((0x$gid))"
	    return;
	fi
	while ((pos < 4)); do
	    digit=`expr index 0123456789ABCDEFGHJKMNPQRTVWXYZ "${gid:$pos:1}"`
	    ((val=val*31+$digit-1))
	    ((++pos))
	done
	;;
    esac
    echo "$((val-=411120))"
}

# gid2id $1; exit

#
#	Query the gc website
#
gc_gid_query() {
    if [ $DEBUG -gt 0 ]; then
	TMP=/tmp/geo
    else
	TMP=/tmp/geo$$
    fi

    HTMLPAGE=$TMP.page
    CIDFILE=$TMP.cids
    LOCFILE=$TMP.loc
    XTRAFILE=$TMP.xtra
    CSVFILE=$TMP.csv
    MERGEFILE=$TMP.merge
    OUTWAY=$TMP.way
    STYLE=$TMP.newstyle

    CRUFT="$CRUFT $HTMLPAGE"
    CRUFT="$CRUFT $CIDFILE"
    CRUFT="$CRUFT $LOCFILE"
    CRUFT="$CRUFT $XTRAFILE"
    CRUFT="$CRUFT $CSVFILE"
    CRUFT="$CRUFT $MERGEFILE"
    CRUFT="$CRUFT $OUTWAY"
    CRUFT="$CRUFT $STYLE"
    if [ $NOCOOKIES = 1 ]; then
	CRUFT="$CRUFT $COOKIE_FILE"
    fi

    #
    #	Login to gc.com
    #
    gc_login "$USERNAME" "$PASSWORD"

    #
    #	We might combine one or more pages into a single XML, so cobble
    #	up a header with the ?xml and loc tags.
    #	
    cat <<-EOF > $LOCFILE
	<?xml version="1.0" encoding="UTF-8"?>
	<loc version="1.0" src="EasyGPS">
	EOF

    URL="$GEO/seek/nearest_cache.aspx"
    URL="$GEOS/seek/nearest.aspx"
    URL="$URL$SEARCH"
    dbgcmd curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" \
	"$URL" > $HTMLPAGE
    rc=$?; if [ $rc != 0 ]; then
	error "curl: fetch $URL"
    fi

    ((qcnt=(GIDCNT+19)/20))
    ((q=0))
    ((i=0))
    > $XTRAFILE
    while ((q < qcnt)); do
	> $CIDFILE
	while ((i < GIDCNT)); do
	    gid=${GID[i]}
	    id=`gid2id "$gid"`
	    echo "-dCID=$id" >> $CIDFILE
	    echo "$gid	Geocache	0	0	0	0" >> $XTRAFILE
	    ((++i))
	    if ((i%20 == 0)); then
		break;
	    fi
	done
	((++q))

        #
        # Grab a few important values from the page
        #
	gc_getviewstate $HTMLPAGE

	dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -A "$UA" \
		-d __EVENTTARGET="$__EVENTTARGET" \
		-d __EVENTARGUMENT="$__EVENTARGUMENT" \
		$viewstate \
		`cat $CIDFILE` \
		-d "Download=Download+Waypoints" \
		"$URL" \
	| sed -e 's/^<?xml [^>]*>//' \
		-e 's/>[gG]eocache</>Geocache</g' \
		-e 's/<loc [^>]*>//' \
		-e 's#</loc>##' \
		-e 's###g' \
		>> $LOCFILE
	rc=$?; if [ $rc != 0 ]; then
	    error "curl: fetch the waypoints"
	fi
	if grep -s -q "you are not logged in" $LOCFILE; then
	    error "you are not logged in on $start"
	fi
	if grep -s -q "has resulted in an error" $LOCFILE; then
	    error "searching error (3) on $start"
	fi
	if grep -s -q "Geocaching > Search for Geocaches" $LOCFILE; then
	    error "searching error (4) on $start"
	fi
	if grep -s -q "recaptcha_challenge_field" $LOCFILE; then
	    error "you are not subscription member!"
	fi

	#
	# Check to see if the user hasn't agreed to license terms
	#
	if grep -s -q "lblAgreementText" $LOCFILE; then
		easy_warning >&2
		remove_cruft
		exit
	fi
    done

    #
    # Finish off the .loc file
    #
    echo "</loc>" >> $LOCFILE

    #
    #	Convert the .loc data to .csv format and join it with
    #	the extra data scraped from the HTML page.  Filter out
    #	the data according to the -I and -X options.
    #
    # http://www.geocaching.com/seek/cache_details.aspx?wp=GCG2H4
    # http://www.geocaching.com/seek/cache_details.aspx?log=y&wp=GCG2H4
    # http://www.geocaching.com/seek/cache_details.aspx?ID=92117&log=y
    #
    # The joined .csv format looks like this:
    #	GCH636	Jidana 3 by rickrich	44.94520	-93.47540 \
    #	http://www.geocaching.com/seek/cache_details.aspx?log=y&wp=GCH636 \
    #	Geocache-ifound-regular	1070285077	1	0	1 \
    #	1067925600	1070285077	0
    #
    make_scrape_style > $STYLE

    dbgcmd gpsbabel -i geo$GEONUKE -f $LOCFILE \
	-o xcsv,style=$STYLE -F $CSVFILE
    if [ $? != 0 ]; then
	error "gpsbabel returned error code [1]"
    fi

    join -t '	' $CSVFILE $XTRAFILE \
    | egrep -- "$INCLUDE" | egrep -v -- "$EXCLUDE" \
    | sed -e 's/wp=/log=y\&&/' > $MERGEFILE

    #
    # Convert to the desired format
    #
    BABELFILT=
    if [ "$RADIUS" != "" ]; then
	BABELFILT="-x radius,distance=$RADIUS,lat=$LAT,lon=$LON"
    fi

    if [ $SQL = 1 ]; then
	    #
	    # add it via mysql
	    #
	    if [ "$OUTFILE" != "" ]; then
		>"$OUTFILE"
	    fi

	    if [ $PURGE = 1 ]; then
		gpsdrive_purge | gpsdrive_mysql
		PURGE=2
	    fi

	    dbgcmd gpsbabel $BABELFLAGS \
		-i xcsv,style=$STYLE -f $MERGEFILE \
		$BABELFILT -o "$OUTFMT" -F $OUTWAY
	    if [ $? != 0 ]; then
		error "gpsbabel returned error code [2]"
	    fi
	    gpsdrive_add <$OUTWAY $SQLTAG | gpsdrive_mysql
    elif [ $MAP = 1 ]; then
	    dbgcmd gpsbabel $BABELFLAGS \
		-i xcsv,style=$STYLE -f $MERGEFILE \
		$BABELFILT -o "$OUTFMT" -F $OUTWAY
	    if [ $? != 0 ]; then
		error "gpsbabel returned error code [3]"
	    fi
	    if [ "$OUTFILE" = "" ]; then
		dbgcmd geo-map -s0 $MAPOPTS -t$OUTWAY
	    else
		dbgcmd geo-map -s0 $MAPOPTS -t$OUTWAY -o"$OUTFILE"
	    fi
    else
	    #
	    # output to stdout or to a file
	    #
	    if [ "$OUTFILE" = "" ]; then
		OUTTMP="$TMP.way";  CRUFT="$CRUFT $OUTTMP"
		dbgcmd gpsbabel $BABELFLAGS \
		    -i xcsv,style=$STYLE -f $MERGEFILE \
		    $BABELFILT -o "$OUTFMT" -F $OUTTMP
		if [ $? != 0 ]; then
		    error "gpsbabel returned error code [4]"
		fi
		cat $OUTTMP
	    else
		dbgcmd gpsbabel $BABELFLAGS \
		    -i xcsv,style=$STYLE -f $MERGEFILE \
		    $BABELFILT -o "$OUTFMT" -F $OUTFILE
		if [ $? != 0 ]; then
		    error "gpsbabel returned error code [5]"
		fi
	    fi
    fi

    #
    #	Optionally, print the HTML pages
    #
    if [ "$CMDPIPE" != "" ]; then
        OIFS="$IFS"
        IFS="	"
        while read id desc lat lon url diff terr container strtype \
            vartime ifound soc iplaced placedt foundt ifoundt extra; do
            url="$url&decrypt=y"
            echo "Print: $url"
	    HTMLPAGE2=$TMP.html
	    CRUFT="$CRUFT $HTMLPAGE2"
	    debug 1 "curl $url" >&2
	    dbgcmd curl $CURL_OPTS -s -A "$UA" -b $COOKIE_FILE "$url" > $HTMLPAGE2
            htmldoc --quiet -t ps --nup 2 --fontsize 14 --webpage $HTMLPAGE2 \
                | psselect -q -p1-1 | eval $CMDPIPE
            # exit
        done < $MERGEFILE
        IFS="$OIFS"
    fi

    #
    #	Optionally, fetch printable HTML pages
    #
    if [ "$HTMLDIR" != ""  -o "$LOGDIR" != "" ]; then
	if [ "$HTMLDIR" != "" -a ! -d "$HTMLDIR" ]; then
	    mkdir "$HTMLDIR" || error "Couldn't mkdir $HTMLDIR"
	fi
	if [ "$LOGDIR" != "" -a ! -d "$LOGDIR" ]; then
	    mkdir "$LOGDIR" || error "Couldn't mkdir $LOGDIR"
	fi

	HTMLPAGE2=$TMP.html
	CRUFT="$CRUFT $HTMLPAGE2"

	OIFS="$IFS"
	IFS="	"
        while read id desc lat lon url diff terr container strtype \
            vartime ifound soc iplaced placedt foundt ifoundt extra; do
	    # Be kind to the server.  Do not remove this sleep
	    sleep $GEOSLEEP

            # Bug in gpsbabel 1.5.2 ...
            url=`echo "$url" | sed 's/.*http:/http:/g' `

	    gc_fetch_cache_page $HTMLPAGE $id $url ""
            if [ $? != 0 ]; then
                continue
            fi

	    if [ "$HTMLDIR" != "" ]; then
		cp $HTMLPAGE "$HTMLDIR/$id.html" ||
		    error "Couldn't copy $id cache page"
	    fi

	    if [ "$LOGDIR" != "" ]; then
		sed -e '1,/Cache find counts/d' -e 's/<STRONG><IMG SRC=/\
&/g' < $HTMLPAGE |
		egrep ">$LOGUSERNAME<|strong> \($LOGUSERNAME\) \(" > $HTMLPAGE2
		lynx -dump $HTMLPAGE2 > $LOGDIR/$id.log
	    fi
	done < $MERGEFILE
	IFS="$OIFS"

	if [ "$LOGDIR" != "" ]; then
	    # This is a hack, and might be innaccurate
	    printf "Finds:" >&2
	    MONTHS="  January |  February |  March |  April |  May |  June "
	    MONTHS="$MONTHS|  July |  August | September |  October "
	    MONTHS="$MONTHS|  November |  December "
	    egrep "$MONTHS" $LOGDIR/*.log |
	    egrep "icon_smile|icon_happy|icon_camera" | wc -l >&2
	fi

    fi
}

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

SEARCH="?origin_lat=$LAT&origin_long=$LON"

i=0
for gid in $*
do
    # Handle common typo of O for 0
    gid=$(echo "$gid" | tr 'O' '0')

    case "$gid" in
    GC*|gc*)
	GID[$i]=$gid
	((++i))
	;;
    *)	# GCID without the "GC"...
	GID[$i]="GC$gid"
	((++i))
	;;
    esac
done
GIDCNT=$i

gc_gid_query
