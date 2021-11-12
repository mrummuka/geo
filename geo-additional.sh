#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Fetch additional waypoints

SYNOPSIS
    `basename $PROGNAME` [options] gid ...

DESCRIPTION
    Fetch additional waypoints from a gc id.

EXAMPLES
    Fetch extra waypoints from FTF HOUNDS MN STYLE - Hal-oween:

	$ geo-additional GC30V8T
	geo-waypoint \$FLAGS N44.54.103 W093.34.027 MU30V8T
	geo-waypoint \$FLAGS N44.54.094 W093.33.896 S130V8T
	geo-waypoint \$FLAGS N44.54.072 W093.34.100 S230V8T
	geo-waypoint \$FLAGS N44.54.172 W093.34.070 S330V8T
	geo-waypoint \$FLAGS N44.54.247 W093.34.079 S430V8T
	geo-waypoint \$FLAGS N44.54.242 W093.34.050 S530V8T
	geo-waypoint \$FLAGS N44.54.219 W093.33.973 S630V8T
	geo-waypoint \$FLAGS N44.54.190 W093.33.947 S730V8T
	geo-waypoint \$FLAGS N44.54.185 W093.33.936 S830V8T
	geo-waypoint \$FLAGS N44.54.142 W093.33.766 S930V8T
	geo-waypoint \$FLAGS N44.54.139 W093.33.765 TE30V8T

OPTIONS
    -D lvl	Debug level
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Process the options
#
read_rc_file

DEBUG=0
while getopts "D:h?" opt
do
	case $opt in
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
HTMLPAGE=$TMP.page
CRUFT="$CRUFT $HTMLPAGE"

process() {
    gcid=$1
    abbrev=` echo $gcid | sed -e "s/GC//" `
    OIFS="$IFS"
    IFS="	";
    while read prefix lookup name coord; do
	if [ "$prefix" = "" -o "$prefix" = Prefix ]; then
	    continue
	fi
	if [ "$coord" != "" ]; then
	    coord=` echo "$coord" \
		    | sed \
		    -e 's/\([NSEW]\) /\1/g' \
		    -e 's/° /./g' \
		` 
	    echo geo-waypoint \$FLAGS $coord $prefix$abbrev
	fi
    done
    IFS="$OIFS"
}

#
#       Get the value from a name= value= pair in a pipe
#
get_value_pipe() {
    # <input type="hidden" name="__EVENTTARGET" value=""
    what=$1
    cat | eval $what=`sed -n "s/^.*\"$what\" *value=\"\([^\"]*\)\".*/\1/p"`
}


#
#	Main Program
#
for i in $*; do
    case $i in
    *.html)
	htmltbl2db -v FCOL=3 -s "Additional Waypoints" -Ft -t1 $i |
	process $i
	;;
    *)
	gc_login "$USERNAME" "$PASSWORD"
	URL="http://www.geocaching.com/seek/cache_details.aspx?wp=$i"
	curl $CURL_OPTS -L -s -A "$UA" -b $COOKIE_FILE \
	    "$URL" > $HTMLPAGE

	gc_getviewstate $HTMLPAGE

	curl $CURL_OPTS -L -s -A "$UA" -b $COOKIE_FILE \
	    $viewstate \
	    "$URL" |
	    geo-htmltbl2db -v FCOL=3 -s "Additional Waypoints" -Ft -t1 |
	    process $i
	;;
    esac
done
