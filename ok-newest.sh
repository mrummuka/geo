#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: ok-newest.sh,v 1.12 2013/02/18 21:41:08 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch a list of newest geocaches from opencaching.us

SYNOPSIS
	`basename $PROGNAME` [options] [state]

	`basename $PROGNAME` [options] state lat lon

	`basename $PROGNAME` [options] country lat lon

DESCRIPTION
	Fetch a list of newest geocaches from opencaching.us.

	Requires:
	    curl	http://curl.haxx.se/

EOF
	ok_usage
	cat << EOF

EXAMPLES
	Add newest 50 caches to a GpsDrive SQL database

	    ok-newest -n50 -f -s -S

	Purge the existing SQL database of all geocaches, and fetch
	200 fresh ones...

	    ok-newest -S -P -s -n200

	Include cross-listed (i.e. gc.com) caches

	    ok-newest -c -s

	Newest in UK:

	    ok-newest -s -E OKBASE=http://www.opencaching.org.uk uk n53.3 w1.5

	Newest in Germany:

	    ok-newest -s -E OKBASE=http://www.opencaching.de germany n50 e7

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-ok"
#include "geo-common-gpsdrive"

ok_state2num() {
	_name="$1"
	_var="$2"
	_prefix="$3"

	case "$_name" in
	al|alabama)		num="1";;
	ak|alaska)		num="2";;
	alberta)		num="3";;
	az|arizona)		num="4";;
	as|arkansas)		num="5";;
	ca|california)		num="6";;
	co|colorado)		num="8";;
	ct|connecticut)		num="9";;
	de|delaware)		num="10";;
	dc)			num="11";;
	fl|florida)		num="12";;
	ga|georgia)		num="13";;
	ha|hawaii)		num="15";;
	id|idaho)		num="16";;
	il|illinois)		num="17";;
	in|indiana)		num="18";;
	ia|iowa)		num="19";;
	ks|kansas)		num="20";;
	ky|kentucky)		num="21";;
	la|louisiana)		num="22";;
	me|maine)		num="23";;
	md|maryland)		num="24";;
	ma|massachusetts)	num="25";;
	mi|michigan)		num="26";;
	mn|minnesota)		num="27";;
	ms|mississippi)		num="28";;
	mo|missouri)		num="29";;
	mt|montana)		num="30";;
	ne|nebraska)		num="31";;
	nv|nevada)		num="32";;
	nh|new\ hampshire)	num="33";;
	nj|new\ jersey)		num="34";;
	nm|new\ mexico)		num="35";;
	ny|new\ york)		num="36";;
	nc|north\ carolina)	num="37";;
	nd|north\ dakota)	num="38";;
	oh|ohio)		num="39";;
	ok|oklahoma)		num="40";;
	or|oregon)		num="41";;
	pa|pennsylvania)	num="42";;
	ri|rhode\ island)	num="44";;
	sc|south\ carolina)	num="45";;
	sd|south\ dakota)	num="46";;
	tn|tennessee)		num="47";;
	tx|texas)		num="48";;
	ut|utah)		num="49";;
	vt|vermont)		num="50";;
	va|virginia)		num="51";;
	wa|washington)		num="53";;
	wv|west\ virginia)	num="54";;
	wi|wisconsin)		num="55";;
	wy|wyoming)		num="56";;
	*)			return 1;;
	esac

	eval _val=\$$_var
	if [ "$_val" = "" ]; then
	    eval $_var="$_prefix$num"
	else
	    _val="$_val $_prefix$num"
	    eval $_var='$_val'
	fi
	return 0
}

ok_country2cc() {
        _name="$1"
        _var="$2"
        _prefix="$3"

        case "$_name" in
	australia)	num="AU";;
	austria)	num="AT";;
	belarus)	num="BY";;
	belgium)	num="BE";;
	bosnia*|herzegowina)	num="BA";;
	brazil)	num="BR";;
	bulgaria)	num="BG";;
	canada)	num="CA";;
	cape\ verde)	num="CV";;
	chad)	num="TD";;
	china)	num="CN";;
	colombia)	num="CO";;
	costa\ rica)	num="CR";;
	croatia)	num="HR";;
	cuba)	num="CU";;
	czech*)	num="CZ";;
	denmark)	num="DK";;
	dominican*)	num="DO";;
	ecuador)	num="EC";;
	egypt)	num="EG";;
	finland)	num="FI";;
	france)	num="FR";;
	georgia)	num="GE";;
	germany)	num="DE";;
	gibraltar)	num="GI";;
	greece)	num="GR";;
	greenland)	num="GL";;
	guatemala)	num="GT";;
	hungary)	num="HU";;
	iceland)	num="IS";;
	india)	num="IN";;
	ireland)	num="IE";;
	italy)	num="IT";;
	japan)	num="JP";;
	jordan)	num="JO";;
	lao*)	num="LA";;
	latvia)	num="LV";;
	liechtenstein)	num="LI";;
	luxembourg)	num="LU";;
	malaysia)	num="MY";;
	maldives)	num="MV";;
	malta)	num="MT";;
	montenegro)	num="ME";;
	morocco)	num="MA";;
	namibia)	num="NA";;
	netherlands)	num="NL";;
	netherlands\ antilles)	num="AN";;
	nz|new\ zealand)	num="NZ";;
	nicaragua)	num="NI";;
	norway)	num="NO";;
	papua*|new\ guinea)	num="PG";;
	poland)	num="PL";;
	portugal)	num="PT";;
	romania)	num="RO";;
	russia)	num="RU";;
	rwanda)	num="RW";;
	seychelles)	num="SC";;
	slovakia)	num="SK";;
	slovenia)	num="SI";;
	south\ africa)	num="ZA";;
	spain)	num="ES";;
	sudan)	num="SD";;
	sweden)	num="SE";;
	switzerland)	num="CH";;
	thailand)	num="TH";;
	togo)	num="TG";;
	trinidad|tobago)		num="TT";;
	tunisia)	num="TN";;
	turkey)	num="TR";;
	ukraine)	num="UA";;
	united\ arab\ emirates)	num="AE";;
	united\ kingdom)	num="GB";;
	uk)			num="GB";;
	us|united\ states)	num="US";;
	us\ minor*)	num="UM";;
	uzbekistan)	num="UZ";;
	vatican)	num="VA";;
	viet\ nam)	num="VN";;
	yemen)	num="YE";;
	esac

        eval _val=\$$_var
        if [ "$_val" = "" ]; then
            eval $_var="$_prefix$num"
        else
            _val="$_val $_prefix$num"
            eval $_var='$_val'
        fi
        return 0
}

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/ok-newest
UPDATE_FILE=ok-newest.new

read_rc_file

#
#       Process the options
#

ok_getopts "$@"
shift $?

#
#	Main Program
#
case "$#" in
8)	STATE="$2"
        COUNTRY="$1"
        # Cut and paste from geocaching.com cache page
        # N 44° 58.630 W 093° 09.310
        LAT=`echo "$3$4.$5" | tr -d '\260\302' `
        LAT=`latlon $LAT`
        LON=`echo "$6$7.$8" | tr -d '\260\302' `
        LON=`latlon $LON`
        ;;
4)      STATE="$2"
        COUNTRY="$1"
        LAT=`latlon $3`
        LON=`latlon $4`
        ;;
3)      STATE="$1"
        LAT=`latlon $2`
        LON=`latlon $3`
        ;;
2)      STATE="$2"
        COUNTRY="$1"
        ;;
1)	STATE="$1";;
0)
        ;;
*)
        usage
        ;;
esac

# http://www.batchgeo.com/lookup/?q=mn

LAT=`latlon $LAT`
LATNS=`degdec2mindec $LAT NS | cut -c 1 `
LATH=`degdec2mindec $LAT NS | sed -e "s/.//" -e "s/\..*//" `
LATMIN=`degdec2mindec $LAT | sed "s/[^.]*\.//" `
LON=`latlon $LON`
LONEW=`degdec2mindec $LON EW | cut -c 1 `
LONH=`degdec2mindec $LON EW | sed -e "s/.//" -e "s/\..*//" `
LONMIN=`degdec2mindec $LON | sed "s/[^.]*\.//" `
if [ "$OKCC" = "" ]; then
    country=`echo $STATE | tr '[A-Z]' '[a-z]'`
    ok_country2cc "$country" CC
    if [ "$CC" = "" ]; then
	OKCC=`echo $COUNTRY | sed 's/^[.]//' `
    else
	OKCC="$CC"
    fi
    SEARCH="searchto=searchbydistance&sort=bycreated"
fi
if [ "$OKCC" = "" ]; then
    state=`echo $STATE | tr '[A-Z]' '[a-z]'`
    ok_state2num "$state" REGION
    if [ "$REGION" != "" ]; then
	SEARCH="searchto=searchbystate&region=$REGION&sort=bycreated"
    fi
fi
SEARCH="$SEARCH&latNS=$LATNS&lat_h=$LATH&lat_min=$LATMIN"
SEARCH="$SEARCH&lonEW=$LONEW&lon_h=$LONH&lon_min=$LONMIN"
#echo "$SEARCH"

ok_query
