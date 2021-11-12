#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-usernum.sh,v 1.8 2017/09/12 18:09:48 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Given a username, print the user account number

SYNOPSIS
	`basename $PROGNAME` [options] [username] ...

DESCRIPTION
	Given a username, print the user account number.  If no
	usernames are given on the comand line, then read usernames
	from stdin, one per line.

	Requires:
	    A free login at http://www.geocaching.com.
	    curl		http://curl.haxx.se/

OPTIONS
	-a aliases	Tab separated alias file [$ALIAS]
	-c		Remove cookie file when done
	-d dbfile	Database file to cache lookups [$DB]
	-f		Force website lookup
	-u username	Username for http://www.geocaching.com
	-p password	Password for http://www.geocaching.com
	-s sleep	Time to sleep between page fetches [$GEOSLEEP]
	-v		Verbose. Print account, username, and URL
	-D lvl		Debug level [$DEBUG]
	-U		Retrieve latest version of this script

	Defaults can also be set with variables in file \$HOME/.georc:

		PASSWORD=password;  USERNAME=username;

EXAMPLE
	Decode the authors name:

	    $ geo-usernum -v rickrich
	    82192 rickrich http://www.geocaching.com/profile/?u=rickrich

SEE ALSO
	geo-count, geo-found, geo-placed,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
ALIAS=$HOME/.geo-alias
DB=$HOME/.geo-usernum
SUMONLY=0
FORCE=0
UPDATE_URL=$WEBHOME/geo-usernum
UPDATE_FILE=geo-usernum.new

#
#       Process the options
#
read_rc_file

VERBOSE=0
DEBUG=0
while getopts "a:cfs:p:u:vD:Uh?-" opt
do
	case $opt in
	a)	ALIAS="$OPTARG";;
	d)	DB="$OPTARG";;
	c)	NOCOOKIES=1;;
	f)	FORCE=1;;
	s)	GEOSLEEP="$OPTARG";;
	u)	USERNAME="$OPTARG";;
	v)	VERBOSE=1;;
	p)	PASSWORD="$OPTARG";;
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

#
#	Main Program
#
touch $DB

if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geousernum
else
    TMP=/tmp/geo$$
fi
TIMESTAMP=${TMP}.timestamp
HTMLPAGE=${TMP}.html
CRUFT="$CRUFT $HTMLPAGE"

do_one() {
    #
    #	See if we have an alias for this user
    #
    REALNAME="$WANTNAME"
    # escape re chars...
    GREPNAME=`echo "$REALNAME" | sed 's/[*]/[*]/g' `
    if [ -r "$ALIAS" ]; then
	RECORD=`grep "^$GREPNAME	" $ALIAS | head -1`
	if [ "$RECORD" != "" ]; then
	    REALNAME=`echo "$RECORD" | sed 's/.*	//' `
	fi
    fi

    case "$REALNAME" in
    _UNKNOWN_|_DEAD_)	exit;;
    esac

    #
    #	See if we already know the number
    #

    # escape re chars...
    GREPNAME=`echo "$REALNAME" | sed 's/[*]/[*]/g' `
    RECORD=`grep "^$GREPNAME	" $DB`
    if [ $FORCE = 0 -a "$RECORD" != "" ]; then
	    USERNUM=`echo "$RECORD" | sed 's/.*	//'`
    else
	if [ $first = 1 ]; then
	    gc_login "$USERNAME" "$PASSWORD"
	    first=0
	fi

	#
	#	get the profile for this user
	#
	URLNAME=`urlencode "$REALNAME" | sed 's/ /+/g' `
	URL="$GEOS/profile/?u=$URLNAME"
	sleep $GEOSLEEP
	debug 1 "list: $URL"
	curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" "$URL" > $HTMLPAGE

	#
	#	Figure out the user number
	#
	#	href="https://forums.geocaching.com/GC/index.php?/profile/4749929-Bouffe/content/"
	USERNUM=`
	    grep "https://forums.geocaching.com/GC/index.php?/profile/" \
		$HTMLPAGE \
	    | sed -e 's/.*profile.//' -e 's/-.*//'
	    `
	debug 1 "USERNUM: $USERNUM"
    fi

    if [ "$USERNUM" != "" ]; then
	echo "$REALNAME	$USERNUM" >> $DB
	sort -t'	' -u -k1,1 -o $DB $DB
	if [ "$VERBOSE" = 1 ]; then
	    URLNAME=`urlencode "$REALNAME" | sed 's/ /+/g' `
	    URL="$GEOS/profile/?u=$URLNAME"
	    printf "%-9s %-18s %s\n" "$USERNUM" "$WANTNAME" "$URL"
	elif [ "$showname" = 1 ]; then
	    printf "%-9s %s\n" "$USERNUM" "$WANTNAME"
	else
	    echo $USERNUM
	fi
    elif [ "$showname" = 1 ]; then
	    echo "?	$WANTNAME"
    fi
}

first=1
showname=1
if [ $# = 0 ]; then
    while read WANTNAME
    do
	do_one
    done
else
    if [ $# = 1 ]; then
	showname=0
    fi
    for WANTNAME in "$@"
    do
	do_one
    done
fi
