#!/bin/bash

#
#	$Id: geo-demand.sh,v 1.114 2017/03/31 20:22:23 rick Exp $
#

#
# N.B. currently does not allow you to set a state/country AND latlon/zip/GC
# at the same time, like the web page does.
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Perform a Pocket Query

SYNOPSIS
    `basename $PROGNAME` [options]

    `basename $PROGNAME` [options] latitude longitude

    `basename $PROGNAME` [options] zipcode

    `basename $PROGNAME` [options] GCxxxx

    `basename $PROGNAME` [options] state [latitude longitude]

    `basename $PROGNAME` [options] country

    `basename $PROGNAME` -o outfmt ....

    `basename $PROGNAME` -k glob-pattern

DESCRIPTION
    Pocket Query with demand by email mode...

	`basename $PROGNAME` [options]
	`basename $PROGNAME` [options] latitude longitude
	`basename $PROGNAME` [options] zipcode
	`basename $PROGNAME` [options] GCxxxx
	`basename $PROGNAME` [options] state
	`basename $PROGNAME` [options] country

	Demand a GPX email of a set of geocaches.

	"state" can be al, ak, ..., wy or "allstates"

	After the query is entered, this script will start a background
	process that will wait 20 minutes, and then the query will be
	deleted.  The "-w" option puts that process in the foreground.
	The "-W" option prevents starting that process at all.

    Instant data delivery mode...

	`basename $PROGNAME` -o outfmt ....

	Any of the command formats above are allowed, and the -o outfmt
	option must be specified.  In this mode, the data is delivered
	instantly, just like with geo-nearest, etc.

    Delete (kill) PQ's by name

	`basename $PROGNAME` -k glob-pattern

	Delete (kill) patterns which match glob-pattern by name.

    Requires:
	- A subscriber login at http://www.geocaching.com.
	- curl		http://curl.haxx.se/

OPTIONS
	-d N[+-]	Difficulty level [$DIFF]
	-t N[+-]	Terrain level [$TERR]
	-e address	Email results to this address [account email address]
	-z		Do not unzip the email contents.
        -n num          Return "num" caches [$NUM]
        -r radius       Return caches within radius (mi or km) [100mi]
	-w		Wait for query to be removed.
	-W		Do not delete query.
	-T period	Placed within last period (week, month, year)
	-T mm/dd/yyyy-mm/dd/yyyy	Placed between two dates.
			Also -mm/dd/yyyy (oldest) and mm/dd/yyyy- (newest)
	-q qualifiers	Limit by one or more space/comma separated qualifiers:

			Type: these ones OR together....
			    traditional, multi, virtual, letterbox, event,
			    mystery, APE, webcam, earth, gps, wherigo
			Container: these ones OR together....
			    small, other, none, large, regular, micro, unknown
			These ones AND together....
			    ifound, notfound, bug, unfound, notowned,
			    new, iown, watchlist, updated, active, notactive,
                            notign, found7, soc, notsoc

	-N name/number	Set the demand query name or number (1-20) [1]
	-a attributes	Set attribute values.

			[~]scenic, [~]dogs, [~]fee, [~]rappelling, [~]boat, 
			[~]scuba, [~]kids, [~]onehour, [~]climbing, 
			[~]wading, [~]swimming, [~]available, [~]night, 
			[~]winter, [~]cliff, [~]hunting, [~]danger, 
			[~]wheelchair, [~]camping, [~]bicycles, 
			[~]motorcycles, [~]quads, [~]jeeps, [~]snowmobiles, 
			[~]campfires, [~]poisonoak, [~]thorn, 
			[~]dangerousanimals, [~]ticks, [~]mine, [~]parking, 
			[~]public, [~]picnic, [~]horses, [~]water, 
			[~]restrooms, [~]phone, [~]stroller, [~]firstaid, 
			[~]cow, [~]stealth, [~]landf, [~]flashlight, [~]rv, 
			[~]uv, [~]snowshoes, [~]skiis, [~]s-tool, 
			[~]nightcache, [~]parkngrab, [~]abandonedbuilding, 
			[~]hike_short, [~]hike_med, [~]hike_long, [~]fuel, 
			[~]food, [~]wirelessbeacon, [~]partnership, 
			[~]field_puzzle, [~]hiking, [~]seasonal, 
			[~]touristok, [~]treeclimbing, [~]frontyard, 
			[~]teamwork, [~]geotour, 

			~keyword means NOT keyword.

        -c              Remove cookie file when done
        -u username     Username for http://www.geocaching.com
        -p password     Password for http://www.geocaching.com
        -U              Retrieve latest version of this script
        -D lvl          Debug level [$DEBUG]

			0: Create and run query, then delete it
			1: Create query but do not run or delete it
			2: More verbose version of -D1
			3: Just show what curl command would be executed

    Instant Data Options:
	-o format	Output format, -o? for possibilities [$OUTFMT]
			plus "gpsdrive.sql" for direct insertion into MySQL DB
			plus "map[,geo-map-opts]" to display a geo-map.
	-O filename	Output file, if not stdout
	-H htmldir	Also fetch the printable HTML pages (slowly)
	-L logdir	Also fetch the plain text log entries (slowly)
	-f              Do not report any found or unavailable caches
	-F		Report caches found by the login 'username' as unfound

    Defaults can also be set with variables in file \$HOME/.georc:

        PASSWORD=password;  USERNAME=username;
        LAT=latitude;       LON=logitude;

EXAMPLES
	Nearest $NUM caches to my home location:

	    geo-demand

	Nearest $NUM caches to a lat/lon:

	    geo-demand 44.53 -93.56
	    geo-demand 44.25.234 -93.51.543

	Nearest $NUM caches to a zip code:

	    geo-demand 55344

	$NUM caches in a state:

	    geo-demand mn

	$NUM caches in a state using lat/lon:

	    geo-demand mn n43.6 w92

	$NUM caches in a country:

	    geo-demand iraq

	$NUM caches in a country by code:

	    geo-demand c12

	$NUM caches in a foreign state:

	    geo-demand berlin

	Caches I have not found, and wait until query is deleted
	before exiting (useful in batch scripts):

	    geo-demand -q notfound -w

	Generate a query, but do not execute it.  Check the gc.com website
	to see what query would have been run...

	    geo-demand -D1

	    Check website: https://www.geocaching.com/pocket/

	Append to the ignore list any caches that were ever SOCs:

	    ignore=\$HOME/.geo-ignore
	    geo-demand -o gpsdrive -qsoc mn |
		awk '{print \$1}' >> \$ignore
		sort -u -o \$ignore \$ignore

	Delete patterns which match "mn-":

	    geo_demand -k mn-

SEE ALSO
	geo-countries-states
	geo-newest, geo-found, geo-placed, geo-nearest,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
PQURL="https://www.geocaching.com/pocket/gcquery.aspx"
UPDATE_URL=$WEBHOME/geo-demand
UPDATE_FILE=geo-demand.new
outputEmail=
CTL="ctl00%24ContentBody%24"


read_rc_file

#
#       Process the options
#
NUM=1000
NUM=500
RADIUS=500
RADIUS_NUM=500
RADIUS_UNITS=mi
WAIT=0
KILL=
PQDELETE=1
TERR="1+"
DIFF="1+"
TIME=none
TYPES=
CONTS=
THATS=
ATTRS=
tbName=DemandQuery1
cbDifficulty=
cbTerrain=
unzip="-d ${CTL}cbZip=on"
# instant output options
FOUND=1
USERFOUND=1
HTMLDIR=
LOGDIR=
OUTFILE=
OUTFMT=
PURGE=0
DELETE=0
SQL=0
MAP=0

while getopts "a:fFo:O:H:k:L:cd:e:t:T:n:N:q:p:r::u:wWzD:Uh?-" opt
do
    case $opt in
    c)	NOCOOKIES=1;;
    e)	outputEmail="$OPTARG";;
    k)	KILL="$OPTARG";;
    z)	unzip="";;
    d)	DIFF="$OPTARG"; cbDifficulty="-d${CTL}cbDifficulty=on";;
    t)	TERR="$OPTARG"; cbTerrain="-d${CTL}cbTerrain=on";;
    T)	TIME="$OPTARG";;
    n)	NUM="$OPTARG"
	case "$NUM" in
	[0-9]*)	;;
	*)	error "Not a number: '$NUM'";;
	esac
	;;
    N)	QNUM="$OPTARG"
	case "$OPTARG" in
	[0-9]*)	tbName="DemandQuery$OPTARG";;
	*)	tbName="`urlencode2 "$OPTARG"`";;
	esac
	;;
    r)	RADIUS="$OPTARG"
	RADIUS_NUM=`awk -v "N=$RADIUS" 'BEGIN{printf "%d\n", N}'`
	case "$RADIUS" in
	*km*|*KM*)      RADIUS_UNITS=km;;
	*)              RADIUS_UNITS=mi;;
	esac
	;;
    w)	WAIT=1;;
    W)	PQDELETE=0;;
    a)
	attrs=`echo "$OPTARG" | sed 's/,/ /g' | tr '[A-Z]' '[a-z]' `
	AA=AttributesListControl1:dtlAttributeIcons:_ctl0:hidInput
	AA=AttributesListControl1:dtlAttributeIcons:_ctl
	AA="${CTL}ctlAttrInclude%24dtlAttributeIcons%24ctl"
	for a in $attrs; do
	    case "$a" in
	    # BEGIN 2017/03/31 src2attr -d ...
	    scenic)                ATTRS="$ATTRS -d${AA}00%24hidInput=1";;
	    ~scenic)               ATTRS="$ATTRS -d${AA}00%24hidInput=2";;
	    dogs)                  ATTRS="$ATTRS -d${AA}01%24hidInput=1";;
	    ~dogs)                 ATTRS="$ATTRS -d${AA}01%24hidInput=2";;
	    fee)                   ATTRS="$ATTRS -d${AA}02%24hidInput=1";;
	    ~fee)                  ATTRS="$ATTRS -d${AA}02%24hidInput=2";;
	    rappelling)            ATTRS="$ATTRS -d${AA}03%24hidInput=1";;
	    ~rappelling)           ATTRS="$ATTRS -d${AA}03%24hidInput=2";;
	    boat)                  ATTRS="$ATTRS -d${AA}04%24hidInput=1";;
	    ~boat)                 ATTRS="$ATTRS -d${AA}04%24hidInput=2";;
	    scuba)                 ATTRS="$ATTRS -d${AA}05%24hidInput=1";;
	    ~scuba)                ATTRS="$ATTRS -d${AA}05%24hidInput=2";;
	    kids)                  ATTRS="$ATTRS -d${AA}06%24hidInput=1";;
	    ~kids)                 ATTRS="$ATTRS -d${AA}06%24hidInput=2";;
	    onehour)               ATTRS="$ATTRS -d${AA}07%24hidInput=1";;
	    ~onehour)              ATTRS="$ATTRS -d${AA}07%24hidInput=2";;
	    climbing)              ATTRS="$ATTRS -d${AA}08%24hidInput=1";;
	    ~climbing)             ATTRS="$ATTRS -d${AA}08%24hidInput=2";;
	    wading)                ATTRS="$ATTRS -d${AA}09%24hidInput=1";;
	    ~wading)               ATTRS="$ATTRS -d${AA}09%24hidInput=2";;
	    swimming)              ATTRS="$ATTRS -d${AA}10%24hidInput=1";;
	    ~swimming)             ATTRS="$ATTRS -d${AA}10%24hidInput=2";;
	    available)             ATTRS="$ATTRS -d${AA}11%24hidInput=1";;
	    ~available)            ATTRS="$ATTRS -d${AA}11%24hidInput=2";;
	    night)                 ATTRS="$ATTRS -d${AA}12%24hidInput=1";;
	    ~night)                ATTRS="$ATTRS -d${AA}12%24hidInput=2";;
	    winter)                ATTRS="$ATTRS -d${AA}13%24hidInput=1";;
	    ~winter)               ATTRS="$ATTRS -d${AA}13%24hidInput=2";;
	    cliff)                 ATTRS="$ATTRS -d${AA}14%24hidInput=1";;
	    ~cliff)                ATTRS="$ATTRS -d${AA}14%24hidInput=2";;
	    hunting)               ATTRS="$ATTRS -d${AA}15%24hidInput=1";;
	    ~hunting)              ATTRS="$ATTRS -d${AA}15%24hidInput=2";;
	    danger)                ATTRS="$ATTRS -d${AA}16%24hidInput=1";;
	    ~danger)               ATTRS="$ATTRS -d${AA}16%24hidInput=2";;
	    wheelchair)            ATTRS="$ATTRS -d${AA}17%24hidInput=1";;
	    ~wheelchair)           ATTRS="$ATTRS -d${AA}17%24hidInput=2";;
	    camping)               ATTRS="$ATTRS -d${AA}18%24hidInput=1";;
	    ~camping)              ATTRS="$ATTRS -d${AA}18%24hidInput=2";;
	    bicycles)              ATTRS="$ATTRS -d${AA}19%24hidInput=1";;
	    ~bicycles)             ATTRS="$ATTRS -d${AA}19%24hidInput=2";;
	    motorcycles)           ATTRS="$ATTRS -d${AA}20%24hidInput=1";;
	    ~motorcycles)          ATTRS="$ATTRS -d${AA}20%24hidInput=2";;
	    quads)                 ATTRS="$ATTRS -d${AA}21%24hidInput=1";;
	    ~quads)                ATTRS="$ATTRS -d${AA}21%24hidInput=2";;
	    jeeps)                 ATTRS="$ATTRS -d${AA}22%24hidInput=1";;
	    ~jeeps)                ATTRS="$ATTRS -d${AA}22%24hidInput=2";;
	    snowmobiles)           ATTRS="$ATTRS -d${AA}23%24hidInput=1";;
	    ~snowmobiles)          ATTRS="$ATTRS -d${AA}23%24hidInput=2";;
	    campfires)             ATTRS="$ATTRS -d${AA}24%24hidInput=1";;
	    ~campfires)            ATTRS="$ATTRS -d${AA}24%24hidInput=2";;
	    poisonoak)             ATTRS="$ATTRS -d${AA}25%24hidInput=1";;
	    ~poisonoak)            ATTRS="$ATTRS -d${AA}25%24hidInput=2";;
	    thorn)                 ATTRS="$ATTRS -d${AA}26%24hidInput=1";;
	    ~thorn)                ATTRS="$ATTRS -d${AA}26%24hidInput=2";;
	    dangerousanimals)      ATTRS="$ATTRS -d${AA}27%24hidInput=1";;
	    ~dangerousanimals)     ATTRS="$ATTRS -d${AA}27%24hidInput=2";;
	    ticks)                 ATTRS="$ATTRS -d${AA}28%24hidInput=1";;
	    ~ticks)                ATTRS="$ATTRS -d${AA}28%24hidInput=2";;
	    mine)                  ATTRS="$ATTRS -d${AA}29%24hidInput=1";;
	    ~mine)                 ATTRS="$ATTRS -d${AA}29%24hidInput=2";;
	    parking)               ATTRS="$ATTRS -d${AA}30%24hidInput=1";;
	    ~parking)              ATTRS="$ATTRS -d${AA}30%24hidInput=2";;
	    public)                ATTRS="$ATTRS -d${AA}31%24hidInput=1";;
	    ~public)               ATTRS="$ATTRS -d${AA}31%24hidInput=2";;
	    picnic)                ATTRS="$ATTRS -d${AA}32%24hidInput=1";;
	    ~picnic)               ATTRS="$ATTRS -d${AA}32%24hidInput=2";;
	    horses)                ATTRS="$ATTRS -d${AA}33%24hidInput=1";;
	    ~horses)               ATTRS="$ATTRS -d${AA}33%24hidInput=2";;
	    water)                 ATTRS="$ATTRS -d${AA}34%24hidInput=1";;
	    ~water)                ATTRS="$ATTRS -d${AA}34%24hidInput=2";;
	    restrooms)             ATTRS="$ATTRS -d${AA}35%24hidInput=1";;
	    ~restrooms)            ATTRS="$ATTRS -d${AA}35%24hidInput=2";;
	    phone)                 ATTRS="$ATTRS -d${AA}36%24hidInput=1";;
	    ~phone)                ATTRS="$ATTRS -d${AA}36%24hidInput=2";;
	    stroller)              ATTRS="$ATTRS -d${AA}37%24hidInput=1";;
	    ~stroller)             ATTRS="$ATTRS -d${AA}37%24hidInput=2";;
	    firstaid)              ATTRS="$ATTRS -d${AA}38%24hidInput=1";;
	    ~firstaid)             ATTRS="$ATTRS -d${AA}38%24hidInput=2";;
	    cow)                   ATTRS="$ATTRS -d${AA}39%24hidInput=1";;
	    ~cow)                  ATTRS="$ATTRS -d${AA}39%24hidInput=2";;
	    stealth)               ATTRS="$ATTRS -d${AA}40%24hidInput=1";;
	    ~stealth)              ATTRS="$ATTRS -d${AA}40%24hidInput=2";;
	    landf)                 ATTRS="$ATTRS -d${AA}41%24hidInput=1";;
	    ~landf)                ATTRS="$ATTRS -d${AA}41%24hidInput=2";;
	    flashlight)            ATTRS="$ATTRS -d${AA}42%24hidInput=1";;
	    ~flashlight)           ATTRS="$ATTRS -d${AA}42%24hidInput=2";;
	    rv)                    ATTRS="$ATTRS -d${AA}43%24hidInput=1";;
	    ~rv)                   ATTRS="$ATTRS -d${AA}43%24hidInput=2";;
	    uv)                    ATTRS="$ATTRS -d${AA}44%24hidInput=1";;
	    ~uv)                   ATTRS="$ATTRS -d${AA}44%24hidInput=2";;
	    snowshoes)             ATTRS="$ATTRS -d${AA}45%24hidInput=1";;
	    ~snowshoes)            ATTRS="$ATTRS -d${AA}45%24hidInput=2";;
	    skiis)                 ATTRS="$ATTRS -d${AA}46%24hidInput=1";;
	    ~skiis)                ATTRS="$ATTRS -d${AA}46%24hidInput=2";;
	    s-tool)                ATTRS="$ATTRS -d${AA}47%24hidInput=1";;
	    ~s-tool)               ATTRS="$ATTRS -d${AA}47%24hidInput=2";;
	    nightcache)            ATTRS="$ATTRS -d${AA}48%24hidInput=1";;
	    ~nightcache)           ATTRS="$ATTRS -d${AA}48%24hidInput=2";;
	    parkngrab)             ATTRS="$ATTRS -d${AA}49%24hidInput=1";;
	    ~parkngrab)            ATTRS="$ATTRS -d${AA}49%24hidInput=2";;
	    abandonedbuilding)     ATTRS="$ATTRS -d${AA}50%24hidInput=1";;
	    ~abandonedbuilding)    ATTRS="$ATTRS -d${AA}50%24hidInput=2";;
	    hike_short)            ATTRS="$ATTRS -d${AA}51%24hidInput=1";;
	    ~hike_short)           ATTRS="$ATTRS -d${AA}51%24hidInput=2";;
	    hike_med)              ATTRS="$ATTRS -d${AA}52%24hidInput=1";;
	    ~hike_med)             ATTRS="$ATTRS -d${AA}52%24hidInput=2";;
	    hike_long)             ATTRS="$ATTRS -d${AA}53%24hidInput=1";;
	    ~hike_long)            ATTRS="$ATTRS -d${AA}53%24hidInput=2";;
	    fuel)                  ATTRS="$ATTRS -d${AA}54%24hidInput=1";;
	    ~fuel)                 ATTRS="$ATTRS -d${AA}54%24hidInput=2";;
	    food)                  ATTRS="$ATTRS -d${AA}55%24hidInput=1";;
	    ~food)                 ATTRS="$ATTRS -d${AA}55%24hidInput=2";;
	    wirelessbeacon)        ATTRS="$ATTRS -d${AA}56%24hidInput=1";;
	    ~wirelessbeacon)       ATTRS="$ATTRS -d${AA}56%24hidInput=2";;
	    partnership)           ATTRS="$ATTRS -d${AA}57%24hidInput=1";;
	    ~partnership)          ATTRS="$ATTRS -d${AA}57%24hidInput=2";;
	    field_puzzle)          ATTRS="$ATTRS -d${AA}58%24hidInput=1";;
	    ~field_puzzle)         ATTRS="$ATTRS -d${AA}58%24hidInput=2";;
	    hiking)                ATTRS="$ATTRS -d${AA}59%24hidInput=1";;
	    ~hiking)               ATTRS="$ATTRS -d${AA}59%24hidInput=2";;
	    seasonal)              ATTRS="$ATTRS -d${AA}60%24hidInput=1";;
	    ~seasonal)             ATTRS="$ATTRS -d${AA}60%24hidInput=2";;
	    touristok)             ATTRS="$ATTRS -d${AA}61%24hidInput=1";;
	    ~touristok)            ATTRS="$ATTRS -d${AA}61%24hidInput=2";;
	    treeclimbing)          ATTRS="$ATTRS -d${AA}62%24hidInput=1";;
	    ~treeclimbing)         ATTRS="$ATTRS -d${AA}62%24hidInput=2";;
	    frontyard)             ATTRS="$ATTRS -d${AA}63%24hidInput=1";;
	    ~frontyard)            ATTRS="$ATTRS -d${AA}63%24hidInput=2";;
	    teamwork)              ATTRS="$ATTRS -d${AA}64%24hidInput=1";;
	    ~teamwork)             ATTRS="$ATTRS -d${AA}64%24hidInput=2";;
	    geotour)               ATTRS="$ATTRS -d${AA}65%24hidInput=1";;
	    ~geotour)              ATTRS="$ATTRS -d${AA}65%24hidInput=2";;
	    # END 2017/03/31 src2attr -d ...
	    *)				usage;;
	    esac
	done
	;;
    q)
	quals=`echo "$OPTARG" | sed 's/,/ /g' | tr '[A-Z]' '[a-z]' `
	for q in $quals; do
	    case "$q" in
	    trad*)		TYPES="$TYPES -d${CTL}cbTaxonomy%240=on";;
	    multi*)		TYPES="$TYPES -d${CTL}cbTaxonomy%241=on";;
	    virtual*)		TYPES="$TYPES -d${CTL}cbTaxonomy%242=on";;
	    letter*)		TYPES="$TYPES -d${CTL}cbTaxonomy%243=on";;
	    event*)		TYPES="$TYPES -d${CTL}cbTaxonomy%244=on";;
	    myst*)		TYPES="$TYPES -d${CTL}cbTaxonomy%245=on";;
	    APE)		TYPES="$TYPES -d${CTL}cbTaxonomy%246=on";;
	    web*)		TYPES="$TYPES -d${CTL}cbTaxonomy%247=on";;
	    earth*)		TYPES="$TYPES -d${CTL}cbTaxonomy%248=on";;
	    gps*)		TYPES="$TYPES -d${CTL}cbTaxonomy%249=on";;
	    where*)		TYPES="$TYPES -d${CTL}cbTaxonomy%2410=on";;

	    small)		CONTS="$CONTS -d${CTL}cbContainers%240=on";;
	    other)		CONTS="$CONTS -d${CTL}cbContainers%241=on";;
	    none)		CONTS="$CONTS -d${CTL}cbContainers%242=on";;
	    large)		CONTS="$CONTS -d${CTL}cbContainers%243=on";;
	    regular)		CONTS="$CONTS -d${CTL}cbContainers%244=on";;
	    micro)		CONTS="$CONTS -d${CTL}cbContainers%245=on";;
	    unknown)		CONTS="$CONTS -d${CTL}cbContainers%246=on";;

	    notfound*)		THATS="$THATS -d${CTL}cbOptions%240=on";;
	    ifound*)		THATS="$THATS -d${CTL}cbOptions%241=on";;
	    notown*)		THATS="$THATS -d${CTL}cbOptions%242=on";;
	    iown|own)		THATS="$THATS -d${CTL}cbOptions%243=on";;
	    notsoc)		THATS="$THATS -d${CTL}cbOptions%244=on";;
	    *member*|soc)	THATS="$THATS -d${CTL}cbOptions%245=on";;
	    notign*)		THATS="$THATS -d${CTL}cbOptions%246=on";;
	    watch*)		THATS="$THATS -d${CTL}cbOptions%247=on";;
	    found7*)		THATS="$THATS -d${CTL}cbOptions%248=on";;
	    *unfound*)		THATS="$THATS -d${CTL}cbOptions%249=on";;
	    *bug*)		THATS="$THATS -d${CTL}cbOptions%2410=on";;
	    new|update*)	THATS="$THATS -d${CTL}cbOptions%2411=on";;
	    notactive)		THATS="$THATS -d${CTL}cbOptions%2412=on";;
	    active)		THATS="$THATS -d${CTL}cbOptions%2413=on";;
	    esac
	done
	;;

    # instant output options
    o)	OUTFMT="$OPTARG";;
    O)	OUTFILE="$OPTARG";;
    H)	HTMLDIR="$OPTARG";;
    L)	LOGDIR="$OPTARG";;
    F)	USERFOUND=0;;
    f)	FOUND=0;;

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
#	Main Program
#
if [ "$KILL" != "" ]; then
    REPLY=$TMP-reply.html; CRUFT="$CRUFT $REPLY"
    REPLY2=$TMP-reply2.html; CRUFT="$CRUFT $REPLY2"
    gc_login "$USERNAME" "$PASSWORD"
    PQURL="https://www.geocaching.com/pocket/"
    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	"$PQURL" > $REPLY

    gc_getviewstate $REPLY

    grep -A1 "gcquery.aspx.guid" $REPLY | tr -d "\r" |
	sed -e "s/^.*href=.//g" -e "s/.>.*$//" \
	>$REPLY2
    ex - $REPLY2 <<-EOF
	g/gcquery/j
	g/^--$/d
	w
	q
	EOF
    while read url name; do
	case "$name" in
	${KILL}*) echo "Kill: $name"
		dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
		    "$url" > $REPLY

		gc_getviewstate $REPLY

		dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
		    $viewstate \
		    -d __EVENTVALIDATION="$__EVENTVALIDATION" \
		    -d "${CTL}btnDelete=Delete+This+Query" \
		    -d "__EVENTTARGET=" \
		    -d "__EVENTARGUMENT=" \
		    "$url"  >/dev/null
		;;
	esac
    done <$REPLY2
    exit
fi

case "$OUTFMT" in
map)
    OUTFMT=tiger,newmarker=grnpin,iconismarker
    MAP=1
    ;;
map,*)
    MAPOPTS=`echo "$OUTFMT" | sed -n 's/map,\(.*\)$/\1/p'`
    OUTFMT=tiger,newmarker=grnpin,iconismarker
    MAP=1
    ;;

gpsdrive.sql)
    OUTFMT=gpsdrive
    SQL=1
    # DEBUG=1
    ;;
\?)
    gpsbabel_formats
    exit
    ;;
esac

if [ "$TYPES" != "" ]; then
    Type=rbTypeSelect
else
    Type=rbTypeAny
fi
if [ "$CONTS" != "" ]; then
    Container=rbContainerSelect
else
    Container=rbContainerAny
fi

tbGC=GCXXXX
CountryState=rbNone
countries=
states=
Origin=rbOriginWpt
while true; do
    case "$#" in
    6)
	    # Cut and paste from geocaching.com cache page
	    # N 44° 58.630 W 093° 09.310
	    LAT=`echo "$1$2.$3" | tr -d '\260\302' `
	    LAT=`latlon $LAT`
	    LON=`echo "$4$5.$6" | tr -d '\260\302' `
	    LON=`latlon $LON`
	    Origin=rbOriginWpt
	    shift 6
	    ;;
    2)
	    LAT=`latlon $1`
	    LON=`latlon $2`
	    Origin=rbOriginWpt
	    shift 2
	    ;;
    1|3)
	    arg=`echo $1 | tr '[A-Z]' '[a-z]'`
	    case "$arg" in
    #include "geo-demand-cs"
	    c[0-9]*)
		code=` echo $arg | tr -c -d '[0-9]' `
		countries="$states -d${CTL}lbCountries=$code"
		;;
	    s[0-9]*)
		code=` echo $arg | tr -c -d '[0-9]' `
		states="$states -d${CTL}lbStates=$code"
		;;
	    allstates)
		((i=1))
		while ((i<=63)); do
		    states="$states -d${CTL}lbStates=$i"
		    ((++i))
		done
		;;

	    [gG][cC][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-z]*)
		Origin=rbOriginGC
		tbGC="$1"
		;;
	    *)			ZIP=$1; Origin=rbPostalCode;;
	    esac

	    if [ "$countries" != "" ]; then
		CountryState=rbCountries
		Origin=rbOriginNone
	    elif [ "$states" != "" ]; then
		CountryState=rbStates
		Origin=rbOriginNone
	    fi
	    shift
	    ;;
    0)
	    # Use home lat/lon
	    Origin=rbOriginWpt
	    ;;
    *)
	    usage
	    ;;
    esac

    if [ "$#" = 0 ]; then
	break
    fi
done

if [ "$outputEmail" != "" ]; then
    outputTo=rbOutputEmail
else
    outputTo=rbOutputAccount
fi

#
#	Validate diff/terr
#
valid_dt() {
    value=$(echo -- "$2" | tr -d '[+\-]')
    value=$(printf "%g" "$value")
    case "$value" in
    [1-5])	echo "$value";;
    [1-4].5)	echo "$value";;
    esac
}

case "$DIFF" in
*+*)	ddDifficulty="%3E%3D"; diff_value=$(valid_dt difficulty "$DIFF");;
*-*)	ddDifficulty="%3C%3D"; diff_value=$(valid_dt difficulty "$DIFF");;
*)	ddDifficulty="%3D"; diff_value=$(valid_dt difficulty "$DIFF");;
esac
if [ "" = "$diff_value" ]; then
    error "Illegal difficulty value '$DIFF'"
fi

case "$TERR" in
*+*)	ddTerrain="%3E%3D"; terr_value=$(valid_dt terrain "$TERR");;
*-*)	ddTerrain="%3C%3D"; terr_value=$(valid_dt terrain "$TERR");;
*)	ddTerrain="%3D"; terr_value=$(valid_dt terrain "$TERR");;
esac
if [ "" = "$terr_value" ]; then
    error "Illegal terrain value '$TERR'"
fi

#
#	Fixup lat/lon into gc.com format
#
lat_ns=`awk -v n=$LAT 'BEGIN{ print (n<0) ? "-1" : "1" }'`
lat_h=`awk -v n=$LAT 'BEGIN{ print (n<0) ? int(-n) : int(n) }'`
lat_mmss=`awk -v n=$LAT 'BEGIN{ if (n<0) n=-n; printf "%06.3f\n", (n*60.0)%60 }' `
lon_ew=`awk -v n=$LON 'BEGIN{ print (n<0) ? "-1" : "1" }'`
lon_h=`awk -v n=$LON 'BEGIN{ print (n<0) ? int(-n) : int(n) }'`
lon_mmss=`awk -v n=$LON 'BEGIN{ if (n<0) n=-n; printf "%06.3f\n", (n*60.0)%60 }' `

#
#	Figure out the time constraint
#
Placed=rbPlacedNone
ddLastPlaced=WEEK
timeStart="last week"
timeEnd="today"
case "$TIME" in
none|"")	;;
week)	Placed=rbPlacedLast; ddLastPlaced=WEEK;;
month)	Placed=rbPlacedLast; ddLastPlaced=MONTH;;
year)	Placed=rbPlacedLast; ddLastPlaced=YEAR;;
-*)	Placed=rbPlacedBetween
	timeStart=01/01/2000
	timeEnd=`echo $TIME | sed 's/.*-//'`
	;;
*-)	Placed=rbPlacedBetween
	timeStart=`echo $TIME | sed 's/-.*//'`
	timeEnd=$($date -d "6 months" +%m/%d/%Y)
	;;
*-*)	Placed=rbPlacedBetween
	timeStart=`echo $TIME | sed 's/-.*//'`
	timeEnd=`echo $TIME | sed 's/.*-//'`
	;;
*)	error "Illegal date format '$TIME'";;
esac

DateTimeBegin_month=`$date -d "$timeStart" +"%m" | sed 's/^0//' `
DateTimeBegin_day=`$date -d "$timeStart" +"%d" | sed 's/^0//' `
DateTimeBegin_year=`$date -d "$timeStart" +"%Y" `
DateTimeEnd_month=`$date -d "$timeEnd" +"%m" | sed 's/^0//' `
DateTimeEnd_day=`$date -d "$timeEnd" +"%d" | sed 's/^0//' `
DateTimeEnd_year=`$date -d "$timeEnd" +"%Y" `

#
# Clamp dates to range permitted by gc.com (else you get a PQ you can't remove)
#
CLAMP_MIN=2000
CLAMP_MAX=2020
if ((DateTimeBegin_year < $CLAMP_MIN)); then
    DateTimeBegin_month=1
    DateTimeBegin_day=1
    DateTimeBegin_year=$CLAMP_MIN
fi
if ((DateTimeEnd_year > $CLAMP_MAX)); then
    thisyear=`$date +"%Y"`
    if [ $thisyear -gt $CLAMP_MAX ]; then
	error "Clamp dates are old: $CLAMP_MAX vs. $thisyear"
    fi
    DateTimeEnd_month=12
    DateTimeEnd_day=31
    DateTimeEnd_year=$CLAMP_MAX
fi

#
#	Login to gc.com
#
if [ "$DEBUG" -lt 3 ]; then
    gc_login "$USERNAME" "$PASSWORD"
fi

#
#	Post the pocket query form
#
#	If debug is on or if we are doing instant output, then
#	don't set any days for the query so no email is sent.
#
#	rbRunOption
#	1		Uncheck the day of the week after the query runs
#	2		Run this query every week on the days checked
#	3		Run this query once then delete it
#
if [ "$DEBUG" = 0 -a "$OUTFMT" = "" ]; then
    days=`TZ=US/Pacific date "+-dcbDays%%3A%w=on"`
    runonce="-d ${CTL}rbRunOption=1"

    days=
    days="$days -d${CTL}cbDays\$0=on"
    days="$days -d${CTL}cbDays\$1=on"
    days="$days -d${CTL}cbDays\$2=on"
    days="$days -d${CTL}cbDays\$3=on"
    days="$days -d${CTL}cbDays\$4=on"
    days="$days -d${CTL}cbDays\$5=on"
    days="$days -d${CTL}cbDays\$6=on"
    runonce="-d ${CTL}rbRunOption=3"
else
    days=
    runonce=
fi

REPLY=$TMP-reply.html; CRUFT="$CRUFT $REPLY"

if [ "$DEBUG" -lt 3 ]; then
    # Get viewstate
    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	"$PQURL" > $REPLY

    gc_getviewstate $REPLY
    echo=
else
    echo=echo
fi

if grep -q '<p class="Warning">' $REPLY; then
    msg=`grep '<p class="Warning">' $REPLY |
	sed -e 's/.*<p class="Warning">//' -e 's/<.p>.*//' -e 's/<[^>]*>//g'
	`
    error "$msg"
fi

$echo dbgcmd curl $CURL_OPTS -L -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	$viewstate \
	-d __EVENTVALIDATION="$__EVENTVALIDATION" \
	-d "${CTL}tbName=$tbName" \
	$days \
	$runonce \
	-d "${CTL}tbResults=$NUM" \
	-d "${CTL}Type=$Type" \
	$TYPES \
	-d "${CTL}Container=$Container" \
	$CONTS \
	$THATS \
	$ATTRS \
	$cbDifficulty \
	-d "${CTL}ddDifficulty=$ddDifficulty" \
	-d "${CTL}ddDifficultyScore=$diff_value" \
	$cbTerrain \
	-d "${CTL}ddTerrain=$ddTerrain" \
	-d "${CTL}ddTerrainScore=$terr_value" \
	-d "${CTL}CountryState=$CountryState" \
	$countries \
	$states \
	-d "${CTL}tbGC=$tbGC" \
	-d "${CTL}tbPostalCode=$ZIP" \
	-d "${CTL}Origin=$Origin" \
	-d "${CTL}LatLong=1" \
	-d "${CTL}LatLong%3A_selectNorthSouth=$lat_ns" \
	-d "${CTL}LatLong%3A_inputLatDegs=$lat_h" \
	-d "${CTL}LatLong%3A_inputLatMins=$lat_mmss" \
	-d "${CTL}LatLong%3A_selectEastWest=$lon_ew" \
	-d "${CTL}LatLong%3A_inputLongDegs=0$lon_h" \
	-d "${CTL}LatLong%3A_inputLongMins=$lon_mmss" \
	-d "${CTL}LatLong%3A_currentLatLongFormat=1" \
	-d "${CTL}tbRadius=$RADIUS_NUM" \
	-d "${CTL}rbUnitType=$RADIUS_UNITS" \
	-d "${CTL}Placed=$Placed" \
	-d "${CTL}ddLastPlaced=$ddLastPlaced" \
	-d "${CTL}DateTimeBegin=$DateTimeBegin" \
	-d "${CTL}DateTimeBegin%24Month=$DateTimeBegin_month" \
	-d "${CTL}DateTimeBegin%24Day=$DateTimeBegin_day" \
	-d "${CTL}DateTimeBegin%24Year=$DateTimeBegin_year" \
	-d "${CTL}DateTimeEnd=$DateTimeEnd" \
	-d "${CTL}DateTimeEnd%24Month=$DateTimeEnd_month" \
	-d "${CTL}DateTimeEnd%24Day=$DateTimeEnd_day" \
	-d "${CTL}DateTimeEnd%24Year=$DateTimeEnd_year" \
	-d "${CTL}Output=$outputTo" \
	-d "${CTL}ddlAltEmails=$outputEmail" \
	-d "${CTL}ddFormats=GPX" \
	$unzip \
	-d "${CTL}btnSubmit=Submit+Information" \
	-d "__EVENTTARGET=" \
	-d "__EVENTARGUMENT=" \
	"$PQURL" > $REPLY

if [ "$DEBUG" -ge 3 ]; then
    cat $REPLY
    exit
fi

PQNUM=$(grep pq= $REPLY | sed -e 's/.*aspx?pq=//' -e 's/".*//')
if [ "$OUTFMT" != "" ]; then
    SEARCH="?pq=$PQNUM"
    gc_query
fi

#
#	If debug is off, spin off a process to delete this query
#	after 20 minutes.
#
if [ "$DEBUG" = 0 -a $PQDELETE = 1 ]; then
    # Get the new viewstate from the reply page
    gc_getviewstate $REPLY

    (
	if [ "$OUTFMT" = "" ]; then
	    sleep 1200
	fi
	curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
		$viewstate \
		-d __EVENTVALIDATION="$__EVENTVALIDATION" \
		-d "${CTL}btnDelete=Delete+This+Query" \
		-d "__EVENTTARGET=" \
		-d "__EVENTARGUMENT=" \
		"$PQURL" > /dev/null
    ) &
    if [ "$WAIT" = 1 ]; then
	wait
    fi
fi
