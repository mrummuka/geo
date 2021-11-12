#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch hi-res PNG aerial photos from a GPX file

SYNOPSIS
	`basename $PROGNAME` [options] gpx-file

DESCRIPTION
	Fetch hi-res PNG format aerial photos for every cache in a GPX file.

OPTIONS
    -f		Force image download even if it already exists
    -W width	Width of image in pixels [$WIDTH]
    -H height	Height of image in pixels [$HEIGHT]
    -a mapsrc	Source for photos, ala geo-map [$MAPSRC]
    -s scale	Scale of photos, ala geo-map {$SCALE]
    -S time	Time to sleep between fetches [$SLEEP]
    -D lvl	Debug level
EOF

	exit 1
}

#include geo-common

#
#       Process the options
#
FORCE=0
SLEEP=0
MAPSRC=tscom
MAPSRC=terra
MAPSRC=osm
MAPSRC=gstatic-aerial
DEBUG=0
WIDTH=500
HEIGHT=500
SCALE=0.5fpp
while getopts "fa:s:S:W:H:D:h?" opt
do
	case $opt in
	f)	FORCE=1;;
	a)	MAPSRC="$OPTARG";;
	s)	SCALE="$OPTARG";;
	W)	WIDTH="$OPTARG";;
	H)	HEIGHT="$OPTARG";;
	S)	SLEEP="$OPTARG";;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
do1() {
    OIFS="$IFS"
    IFS="|"
    gpsbabel -igpx -f$1 -otabsep -F- | tr '	' '|' |
    while read index shortname description notes url urltext icon lat lon \
        lat32 lon32 latdecdir londecdir latdirdec londirdec latdir londir \
        altfeet altmeters excel timet diff terr container type extra; do
	if [ $FORCE = 1 -o ! -s "$shortname.png" ]; then
	    echo "$shortname.png"
	    description=$(echo "$description" | tr -d '"' | tr '`' "'")
	    latmin=`degdec2mindec $lat`
	    lonmin=`degdec2mindec $lon`
	    geo-map -a$MAPSRC -s$SCALE -o "$shortname.png" \
		-W "$WIDTH" -H "$HEIGHT" \
		-T "$shortname   $description   $latmin $lonmin" \
		$lat $lon ""
	    sleep $SLEEP
	fi
    done
    IFS="$OIFS"
}

for i in $*
do
    do1 $i
done
