#!/bin/bash

#
#	$Id: geo-pqdownload.sh,v 1.37 2016/04/23 08:44:47 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Perform a Pocket Query download(s)

SYNOPSIS
    `basename $PROGNAME` [options]

DESCRIPTION
    Pocket Query download. For PQ's from 501 to 1000 waypoints, because the
    gc site does not email them (as of May 10, 2010).  Go figure!!!

OPTIONS
        -c              Remove cookie file when done
	-d		Delete the files from the server
	-n NAME		Search for NAMEs, globbing allowed
	-t name		Construct name using strftime specifiers, PLUS
			%+ for the actual name. I.E.
			    -t %m%d-%+
	-z		Unzip the files
        -u username     Username for http://www.geocaching.com
        -p password     Password for http://www.geocaching.com
        -U              Retrieve latest version of this script
        -D lvl          Debug level [$DEBUG]

    Defaults can also be set with variables in file \$HOME/.georc:

        PASSWORD=password;  USERNAME=username;
        LAT=latitude;       LON=logitude;

EXAMPLES
    Download all files:

	$ geo-pqdownload -d -z
	mn-09   http://www.geocaching.com/pocket/downloadpq.ashx?g=ba2e0520...
	mn-28   http://www.geocaching.com/pocket/downloadpq.ashx?g=41a95f02...
	mn-29   http://www.geocaching.com/pocket/downloadpq.ashx?g=cff93db9...
	mn-30   http://www.geocaching.com/pocket/downloadpq.ashx?g=e5049240...
	$ ls *.zip *.gpx
	mn-09.gpx         mn-28.gpx         mn-29.gpx         mn-30.gpx
	mn-09-wpts.gpx    mn-28-wpts.gpx    mn-29-wpts.gpx    mn-30-wpts.gpx
	mn-09.zip         mn-28.zip         mn-29.zip         mn-30.zip

    Download "My Finds.." files:

	$ geo-pqdownload -d -z -n "My*"

    Download "My Finds.." files prefixed with year-month-day:

	$ geo-pqdownload -d -z -n "My*" -t %Y-%m-%d-%+
	$ ls *My*
	2011-05-06-My Finds Pocket Query.zip

    Download all files *except* the "My*" file:

	$ geo-pqdownload -n "!(My*)"

SEE ALSO
	geo-countries-states
	geo-newest, geo-found, geo-placed, geo-nearest,
	strftime,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
PQURL="https://www.geocaching.com/pocket/default.aspx"
UPDATE_URL=$WEBHOME/geo-pqdownload
UPDATE_FILE=geo-pqdownload.new
outputEmail=
CTL="ctl00%24ContentBody%24"

read_rc_file

DELETE=0
UNZIP=0
SEARCH=
TIMESTR=

#
#       Process the options
#
while getopts "cdn:p:t:u:zD:Uh?-" opt
do
    case $opt in
    c)	NOCOOKIES=1;;
    d)	DELETE=1;;
    n)	SEARCH="$OPTARG";;
    t)	TIMESTR="$OPTARG";;
    z)	UNZIP=1;;
    u)	USERNAME="$OPTARG";;
    p)	PASSWORD="$OPTARG";;
    D)	DEBUG="$OPTARG";;
    U)	echo "Getting latest version of this script..."
	curl $CURL_OPTS -o$UPDATE_FILE "$UPDATE_URL"
	chmod +x "$UPDATE_FILE"
	echo "Latest version is in $UPDATE_FILE"
	exit
	;;
    h|\?|-) usage;;
    esac
done
shift `expr $OPTIND - 1`

DBGCMD_LVL=2
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi
if [ $NOCOOKIES = 1 ]; then
    CRUFT="$CRUFT $COOKIE_FILE"
fi

#
#	make_db
#		id url name
#
#	myfinds	http://www.geocaching.com/pocket/downloadpq.ashx?g=169d0f6c-50d6-40e4-bbf5-a269a3b9b48c My Finds Pocket Query
#	5085665	http://www.geocaching.com/pocket/downloadpq.ashx?g=e0280e9f-a00d-4e33-b5e2-20bd4100ecba mn-13
#	5085708	http://www.geocaching.com/pocket/downloadpq.ashx?g=d4c43a8a-aa62-403e-ab34-6180efba6ea0 mn-14
#	5085754	http://www.geocaching.com/pocket/downloadpq.ashx?g=e4dbdeda-aa3a-4b6b-ad33-95461eae3276 mn-15
#
make_db () {
    awk -v GEO=$GEOS <$1 '
	BEGIN {
	    id = "myfinds"
	}
	$0 ~ "id=.chk" {
	    id = $0
	    sub(".*value=.", "", id)
	    sub(". .*", "", id)
	}
	$0 ~ "downloadpq.ashx?" {
	    url = $0
	    sub("^ *<a href=.", "", url)
	    sub(".>.*", "", url)

	    getline
	    name = $0
	    sub("^ *", "", name)
	    sub("</a>.*", "", name)
	    printf "%s\t%s\t%s\n", id, GEO url, name
	}
    '
}

#
#	Main Program
#

#
#	Login to gc.com
#
if [ "$DEBUG" -lt 5 ]; then
    gc_login "$USERNAME" "$PASSWORD"
fi

REPLY=$TMP-reply.html; CRUFT="$CRUFT $REPLY"
CIDS=$TMP.cids; CRUFT="$CRUFT $CIDS"
DB=$TMP.db; CRUFT="$CRUFT $DB"

if true; then
    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	$viewstate \
	-d __EVENTVALIDATION="$__EVENTVALIDATION" \
	-d "__EVENTTARGET=" \
	-d "__EVENTARGUMENT=" \
	"$PQURL" > $REPLY

    gc_getviewstate $REPLY
fi

make_db $REPLY > $DB
#cat $DB
#exit

shopt -s extglob
> $CIDS
if true; then
    while read id url name; do
	debug 1 "$id	$url	$name"

	case "$name" in
	$SEARCH)	;;
	*)		if [ "$SEARCH" != "" ]; then continue; fi;;
	esac 

	if [ "$TIMESTR" != "" ]; then
	    name=` echo "$TIMESTR" | sed "s/%[+]/$name/" `
	    name=` date +"$name" `
	    debug 1 "$id	$url	$name"
	fi

	dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	    $viewstate \
	    -d __EVENTVALIDATION="$__EVENTVALIDATION" \
	    -d "__EVENTTARGET=" \
	    -d "__EVENTARGUMENT=" \
	    "$url" > "$name".zip

	contents=`file "$name".zip`
	debug 1 "$contents"
	case "$contents" in
	*Zip*)	;;
	*HTML*)
		err=`grep "%2ferror%2f" "$name".zip`
		if [ "$err" != "" ]; then
		    error "gc.com: 500 - Internal server error"
		fi
		continue;;
	*)	continue;;
	esac

	if [ -s "$name".zip ]; then
	    printf "$id," >> $CIDS
	    echo "$name	$url"
	else
	    sleep $GEOSLEEP
	    continue
	fi

	sleep $GEOSLEEP

	if [ $UNZIP = 1 ]; then
	    test -d .pqdownload || mkdir .pqdownload
	    cd .pqdownload || error "Couldn't mkdir .pqdownload"
	    unzip -q -o ../"$name".zip
	    for f in *.gpx; do
		#4599797.gpx to ../mn-30.gpx
		#4599797-wpts.gpx to ../mn-30-wpts.gpx
		case "$f" in
		*-wpts.gpx) target="$name-wpts.gpx";;
		*.gpx)      target="$name.gpx";;
		esac
		mv "$f" "../$target"
	    done
	    cd ..
	    rm -rf .pqdownload
	fi
    done < $DB
    echo "" >> $CIDS
fi

if [ $DELETE = 1 ]; then
    delsel=`grep DeleteSel $REPLY |
	sed -e 's/.*__doPostBack(.//' \
	    -e 's/&#39;,.*//' -e 's/#39;//' \
	    -e "s/'.*//" `
    debug 1 "delsel: $delsel"

    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	$viewstate \
	-d __EVENTVALIDATION="$__EVENTVALIDATION" \
	-d "__EVENTTARGET=$delsel" \
	-d "__EVENTARGUMENT=" \
	-d "ctl00%24ContentBody%24PQListControl1%24hidIds=" \
	-d "ctl00%24ContentBody%24PQDownloadList%24hidIds=`cat $CIDS`" \
	"$PQURL" > /dev/null
fi
