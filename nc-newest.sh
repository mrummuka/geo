#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: nc-newest.sh,v 1.17 2013/02/18 21:41:07 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch a list of newest geocaches

SYNOPSIS
	`basename $PROGNAME` [options] [state]

	`basename $PROGNAME` [options] [state] [lat] [lon]

DESCRIPTION
	Fetch a list of newest geocaches.

	Requires:
	    curl	http://curl.haxx.se/

EOF
	nc_usage
	cat << EOF

EXAMPLES
	Add newest 50 caches to a GpsDrive SQL database

	    nc-newest -n50 -f -s -S MN

	Purge the existing SQL database of all geocaches, and fetch
	200 fresh ones...

	    nc-newest -S -P -s -n200 MN

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-nc"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/nc-newest
UPDATE_FILE=nc-newest.new
STATE=MN

read_rc_file

#
#       Process the options
#

nc_getopts "$@"
shift $?

PLACE="$STATE"
STATE=

#
#	Main Program
#
case "$#" in
3)	PLACE="$1"
	LAT=`latlon $2`
	LON=`latlon $3`
	;;
1)	PLACE="$1";;
0)	;;
*)	usage;;
esac

case "$PLACE" in
al|AL|Alabama)		STATE=AL;;
ak|AK|Alaska)		STATE=AK;;
az|AZ|Arizona)		STATE=AZ;;
as|AS|Arkansas)		STATE=AS;;
ca|CA|California)	STATE=CA;;
co|CO|Colorado)		STATE=CO;;
ct|CT|Connecticut)	STATE=CT;;
dc|DC)			STATE=DC;;
de|DE|Delaware)		STATE=DE;;
fl|FL|Florida)		STATE=FL;;
ga|GA|Georgia)		STATE=GA;;
ha|HA|Hawaii)		STATE=HA;;
id|ID|Idaho)		STATE=ID;;
il|IL|Illinois)		STATE=IL;;
in|IN|Indiana)		STATE=IN;;
ia|IA|Iowa)		STATE=IA;;
ks|KS|Kansas)		STATE=KS;;
ky|KY|Kentucky)		STATE=KY;;
la|LA|Louisiana)	STATE=LA;;
me|ME|Maine)		STATE=ME;;
md|MD|Maryland)		STATE=MD;;
ma|MA|Massachusetts)	STATE=MA;;
mi|MI|Michigan)		STATE=MI;;
mn|MN|Minnesota)	STATE=MN;;
ms|MS|Mississippi)	STATE=MS;;
mo|MO|Missouri)		STATE=MO;;
mt|MT|Montana)		STATE=MT;;
ne|NE|Nebraska)		STATE=NE;;
nv|NV|Nevada)		STATE=NV;;
nh|NH|New\ Hampshire)	STATE=NH;;
nj|NJ|New\ Jersey)	STATE=NJ;;
nm|NM|New\ Mexico)	STATE=NM;;
ny|NY|New\ York)	STATE=NY;;
nc|NC|North\ Carolina)	STATE=NC;;
nd|ND|North\ Dakota)	STATE=ND;;
oh|OH|Ohio)		STATE=OH;;
ok|OK|Oklahoma)		STATE=OK;;
or|OR|Oregon)		STATE=OR;;
pa|PA|Pennsylvania)	STATE=PA;;
ri|RI|Rhode\ Island)	STATE=RI;;
sc|SC|South\ Carolina)	STATE=SC;;
sd|SD|South\ Dakota)	STATE=SD;;
tn|TN|Tennessee)	STATE=TN;;
tx|TX|Texas)		STATE=TX;;
ut|UT|Utah)		STATE=UT;;
vt|VT|Vermont)		STATE=VT;;
va|VA|Virginia)		STATE=VA;;
wa|WA|Washington)	STATE=WA;;
wv|WV|West\ Virginia)	STATE=WV;;
wi|WI|Wisconsin)	STATE=WI;;
wy|WY|Wyoming)		STATE=WY;;

Germany)		COUNTRY=DE;;
fr|FR|France)		COUNTRY=FR;;
uk|UK|United\Kingdom)	COUNTRY=UK;;
*)			error "Unknown state or country '$PLACE'";;
esac

CMD=newest
nc_query
