#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-map.sh,v 1.383 2018/10/23 20:50:03 rick Exp $
#

PROGNAME="$0"

usage() {
	range=`awk 'BEGIN {
		    printf "%.2f", (10000.0/2817.947378) * 1024.0 / 1609.344
		}'`
    
	cat <<EOF
NAME
    `basename $PROGNAME` - Create and display a map centered about a lat/lon

SYNOPSIS
    `basename $PROGNAME` [options] latitude longitude [label [symbol]] ...

DESCRIPTION
    Create and display a map centered about a latitude/longitude.
    Lat/Lon may be in DegDec, MinDec, or DMS formats.

    I believe that fair use allows you to use the mapblast and expedia
    maps for yourself, but you CANNOT republish those maps.  The tiger
    and terraserver/toposerver maps have no restrictions.

    Acceptable formats for lat/lon are:

	-93.49130	DegDec (decimal degrees)
	W93.49130	DegDec (decimal degrees)
	"-93 29.478"	MinDec (decimal minutes)
	"W93 29.478"	MinDec (decimal minutes)
	-93.29.478	MinDec (decimal minutes)
	W93.29.478	MinDec (decimal minutes)
	W 93° 29.478	Cut/paste from gc.com (note it is 3 arguments)
	"-93 45 30"	DMS (degrees, minutes, seconds)

    "label" can be any text and will be displayed by the waypoint.
    The default label is the coordinates in MinDec format, and can
    be explicitly selected with the label "@".

    "symbol" can be these tiger-style symbols

	cross, redstar, bluestar
	<clr>pin
	<clr>dot<size>
	    <clr> is red, grn, blu, org, pur, mag, brn, lgr, cyn, gry, wht
	    e.g. reddot10

    "symbol" can also be these extensions:

	cross,<color>,<size>
	dot,<color>,<diameter>
	    <color> is any color allowed by convert(1)
	    <size> is the length in pixels of the crosses or the diameter
	    of the dot.
	circle,<color>,<radius>
	circle,<color>,<radius>,<thick>
	    <radius> is in pixels, meters(m), kilometers(km),
		     feet(ft), or miles(mi).
	gc
	    Do geocaching.com circle of radius 0.1 miles
	puzzle
	    Do geocaching.com circle of radius 2.0 miles
	line,<color>,<thick>
	    Draw a line from the previous point
	hline,<color>,<thick>
	    Draw a horizontal line
	vline,<color>,<thick>
	    Draw a vertical line
	xhair,<color>,<thick>
	    Draw a crosshair
	<filename>.{gif,jpg,png}
	<filename>.{gif,jpg,png},xsize,ysize
	<filename>.{gif,jpg,png},xsize,ysize,xoff,yoff
	geocache-event geocache-hybrid geocache-multi geocache-regular
	geocache-unknown geocache-virtual geocache-webcam geocache-moving
	geocache-ifound-event geocache-ifound-hybrid geocache-ifound-multi
	geocache-ifound-regular geocache-ifound-unknown geocache-ifound-virtual
	geocache-ifound-webcam geocache-ifound-moving
	geocache-unfound-event geocache-unfound-hybrid
	geocache-unfound-multi geocache-unfound-regular
	geocache-unfound-unknown geocache-unfound-virtual
	geocache-unfound-webcam geocache-unfound-moving

    The default symbol is "cross,red,10" and can be explicitly selected
    with the symbol "@".

OPTIONS
    -a number	Use map source number/name: [$MAPSRC]

		1 mapblast/vicinity	2 expedia	3 tiger

		4 terraserver          5 toposerver      (free USGS)

		6 gc                   7 gc-icons

		8 multimap (worldwide) 9 multimap-aerial (UK only)

		13 tscom OR citipix OR globex OR tscom:citipix
                       OR tscom:airphoto OR tscom:digitalglobe OR tscom:globex
		       OR tscom:getmapping OR tscom:getmappingultra.
		       Best is 22544:1 unless a terraserver.com member who sets
		       TSCOM_EMAIL and TSCOM_PW in \$HOME.georc.

		20 osm OR osmmapnik OR osmapnik

		21 osmstatic

		30 aolterra

		40 gmap (Google Maps) OR gbike

		41 gstatic
		42 gstatic-hybrid
		43 gstatic-terrain
		44 gstatic-aerial

		50 leaflet

		TMS: may not be available/current everywhere
		91 tms-osm (OSM Tile Map Server tile.openstreetmap.org)
		92 tms-osmcycle OR tms-ocm
		 - tms-transport OR tms-trans (experimental)
		 - tms-openptmap OR tms-pt
		 - tms-openrailwaymap OR tms-rail
		93 tms-osmde         (Roads German style)
		 - tms-humanitarian OR tms-hot
		94 tms-mapquest OR tms-mq
		 - tms-openaerial OR tms-mqoa
		95 tms-maptoolkit OR tms-mtk
		96 tms-gpsies
		 - tms-thunderforest OR tms-outdoors
		97 tms-terrain       (Stamen, US only)
		98 tms-toner         (Stamen)
		99 tms-watercolor    (Stamen)

		 - tms-gif-*         (GIF TMS, append base URL)
		 - tms-jpg-*
		 - tms-png-*


    -a black	Black map
    -a white	White map
    -a gray	Gray map (for no map at all)

    -a url	Don't generate a map, instead output a URL link.

    -a file.png	Overlay existing gif or png image with waypoints.
    -c		Label map with coordinates
    -C		Force 1st comand line coordinate to be the center
    -m		Do not display marker(s) (symbols)
    -s scale	Map scale NNNNN:1 [$MAPSCALE]

		    Units modifiers: K = 1,000 and M = 1,000,000
		    N.B. A 1024 pixel map at a scale of 10K is $range miles.

		Or specify the scale by image resolution:
		    NNNmpp = meters/pixel, NNNfpp or NNNft = feet/pixel,
		    NNNipp or NNNin = inches/pixel (6in res for some sources)

    -s 0	Autoscale.  Use bounding box of waypoints.
    -r radius	Minimum 'radius' (square circle) for autoscaled map.
		Units are in degrees unless suffixed with km or mi.
    -R radius	Maximum 'radius' (square circle) for autoscaled map.
		Units are in degrees unless suffixed with km or mi.
    -S symbol   Set the default symbol [$SYMBOL]
    -W width	Width of image in pixels [$MAPWIDTH]
    -H height	Height of image in pixels [$MAPHEIGHT]
    -o file	Save map in file, do not display it. Also:
    -o www	Upload: put-rkkda rkkda/tmp 111.jpg

    -o www:file	Upload: put-rkkda rkkda/tmp file
    -h file	Write an HTML imagemap to file.  Requires -t and -o.
		If the file is +file, then append the map to the file.
    -i		Use smaller icons and labels. Drop coordinates from label.
    -t waypts	A file of waypoints to plot in tabsep, GPX, LOC, geo-mystery,
		or in extended Tiger format:

			LONG,LAT:SYMBOL:LABEL:URL
		The map will be centered about the 1st command line
		coordinate.  If there isn't one, it will be centered
		about the bounding box of the coordinates.

    -g mins[,color] 
		Add a lat/lon grid every minutes (decimal allowed).
		Suffix mins with "d" for degrees.  Grid lines are red
		unless "color" is specified.
    -T title	Title to put on image.
    -F footer	Footer to put on image.

		Escapes for -T and -F:
		    %a positional params
		    %A entire command line
    -B		Show km bar scale
    -b		Show mi bar scale
    -j dir[,amt]
		Jog the center of the picture to n/s/e/w/ne/se/nw/sw by 80%
    -P file	Output gpsbabel polygon (square) to file
    -k key	Set the Google Map key, i.e. GMAP_KEY in \$HOME/.georc
    -D lvl	Debug level [$DEBUG]
    -U		Retrieve latest version of this script

    Defaults can also be set with variables in file \$HOME/.georc:

	MAPSRC=number;  MAPSCALE=scale;  MAPWIDTH=width;  MAPHEIGHT=height;
	MAPTEXTBG=white    #Can also use #rrggbbaa and "none" for no box
	MAPTEXTFG=black    #Can also use #rrggbbaa
	GMAP_KEY=AAaaAaA0A00AAaAA0AA0aaAAAAAAaaAAAAaa00A	#Key for Google

EXAMPLES
    A single waypoint displayed on a map, label is lat/lon:

	geo-map 45.50.501 W93.23.609

    Two waypoints, map scale determined automatically:

	geo-map -s0 N44.48.938 W093.31.988 riley cross \\
		    N44.49.245 W093.30.507 yogurt redstar

    Many waypoints from a Tiger-style waypoint file:

	geo-map -s0 -t /tmp/mngca/TwinCities.tiger

    A mailable URL from a Tiger-style waypoint file:

	geo-map -aurl -s0 -t /tmp/mngca/TwinCities.tiger

    An HTML imagemap from a Tiger-style waypoint file:

	geo-map -s0 -t test.tiger -h test.html -o test.png

    A GIANT imagemap of Twin Cities area caches:

	geo-map -a3 -s30k -W7400 -H7000 -m -o map.png 45 -93.25
	geo-nearest -ogpx -n700 45 -93.25 > tc700.gpx
	geo-map -a map.png -t tc700.gpx -s30k -o big.png -h big.html 45 -93.25

    A google map with 0.1mi circles:

	geo-map -S gc -a gmap -t ~/Caches/xxx.gpx -o www:xxx.html

    A triangle with the centroid:

	geo-map -aosm -s0 N29.29.730 W98.39.806 \\
	    N29.29.652 W98.39.943 a line,red,1 \\
	    N29.29.793 W98.39.954 b line,red,1 \\
	    N29.29.730 W98.39.806 c line,red,1 \\
	    n29.29.725 w98.39.901 e dot,red,1

SEE ALSO
    geo-code, geo-nearest, geo-pg, geo-waypoint,
    $WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#	Procedure to unpack the pushpin images
#
GEODIR=/tmp/geo
IMGDIR=$GEODIR/images
unpacked=0
unpack_images() {
    if [ $unpacked != 0 ]; then
	return
    fi
    case "$1" in
	*.gif)	return;;
	redstar|bluestar|cross|*pin|[Gg]eocache*|*dot*)
	    [ -d $GEODIR ] || mkdir $GEODIR || error 1 "Can't mkdir $GEODIR"
	    # mimencode -u <<-\EOF | (cd $GEODIR; cpio -icdu --quiet)
	    uudecode <<-\EOF
#include "geo-images"
		EOF
	    (cd $GEODIR; cpio -icdu --quiet <$GEODIR/images.cpio)
	    chmod 777 $IMGDIR
	    chmod 666 $IMGDIR/*
	    unpacked=1
	;;
    esac
}

#
#	Procedure to compute the scale needed for the bounding box
#
calc_scale() {
    awk \
    -v LATmin=$1 \
    -v LONmin=$2 \
    -v LATmax=$3 \
    -v LONmax=$4 \
    -v WIDTH=$5 \
    -v HEIGHT=$6 \
    -v PIXELFACT=$PIXELFACT \
    '
    function calcR(lat)
    {
	lat = lat * M_PI_180
	sc = sin(lat)
	x = A * (1.0 - E2)
	z = 1.0 - E2 * sc * sc
	y = z ^ 1.5
	r = x / y
	return r * 1000.0
    }

    function asin(x)	{ return atan2(x,(1.-x^2)^0.5) }

    # Rough calculation of distance on an ellipsoid
    function dist(lat1, lon1, lat2, lon2,
		    radiant, dlon, dlat, a1, a2, a, sa, c)
    {
	radiant = M_PI_180
	dlon = radiant * (lon1 - lon2);
	dlat = radiant * (lat1 - lat2);
	a1 = sin(dlat / 2.0)
	a2 = sin (dlon / 2.0)
	a = (a1 * a1) + cos(lat1 * radiant) * cos(lat2 * radiant) * a2 * a2
	sa = sqrt(a)
	if (sa <= 1.0)
	    c = 2 * asin(sa)
	else
	    c = 2 * asin(1.0)
	return (Ra[int(100 + lat2)] + Ra[int(100 + lat1)]) * c / 2.0;
    }

    BEGIN {
	A = 6378.137
	E2 = 0.081082 * 0.081082
	M_PI = 3.14159265358979323846
	M_PI_180 = M_PI / 180.0
	# Build array for earth radii
	for (i = -100; i <= 100; i++)
	    Ra[i+100] = calcR(i)

	dlat = dist(LATmin, LONmin, LATmax, LONmin) * 1.2
	dlon = dist(LATmin, LONmin, LATmin, LONmax) * 1.2
	if (dlon/WIDTH > dlat/HEIGHT)
	{
	    dimage = WIDTH / PIXELFACT
	    dphys = dlon
	}
	else
	{
	    dimage = HEIGHT / PIXELFACT
	    dphys = dlat
	}
	if (dphys < 1)
	    print 1000
	else
	    printf "%d", dphys / dimage
    }
    '
}

#
#	Given a lat/lon, a distance in meters, and a compass bearing,
#	calculate the approximate lat/lon.  The first argument is the
#	type of data to output:
#		lat	new latitude only
#		lon	new longitude only
#		latlon	both
#		dlat	delta latitude only
#		dlon	delta longitude only
#		dlatlon	both
#
calc_latlon() {
    awk \
    -v type=$1 \
    -v lat0=$2 \
    -v lon0=$3 \
    -v dist=$4 \
    -v bear=$5 \
    '
    function pow(a, b)      { return a ^ b }
    function asin(x)        { return atan2(x,(1.-x^2)^0.5) }
    function acos(x)        { return atan2((1.-x^2)^0.5,x) } 
    BEGIN {
	A = 6378.14;
	E = 0.08181922; E2 = E*E
	M_PI = 3.14159265358979323846; M_PI_180 = M_PI / 180.0

	# Convert to radians
	lat0r = lat0 * M_PI_180
	lon0r = lon0 * M_PI_180
	bear = -bear * M_PI_180

	R = A*(1-E2)/pow((1-E2*pow(sin(lat0r),2)), 1.5);
	psi = (dist/1000.0) / R
	phi = M_PI/2 - lat0r;

	if (type ~ /lat/)
	{
	    arccos = cos(psi)*cos(phi) + sin(psi)*sin(phi)*cos(bear);
	    latA = (M_PI/2-acos(arccos)) / M_PI_180
	    if (type ~ /^d/)
		printf "%.6f\n", latA - lat0
	    else
		printf "%.6f\n", latA
	}
	if (type ~ /lon/)
	{
	    arcsin = sin(bear)*sin(psi)/sin(phi);
	    lonA = (lon0r - asin(arcsin)) / M_PI_180
	    if (type ~ /^d/)
		printf "%.6f\n", lonA - lon0
	    else
		printf "%.6f\n", lonA
	}
    }
    '
}

#
# Floating point min/max
#
fmin() {
    awk -v m=$1 -v v=$2 'BEGIN{if (v<m) print v; else print m}'
}
fmax() {
    awk -v m=$1 -v v=$2 'BEGIN{if (v>m) print v; else print m}'
}

fmindelta() {
    awk -v m=$1 -v v=$2 -v d=$3 'BEGIN{ v-=d; if (v<m) print v; else print m}'
}
fmaxdelta() {
    awk -v m=$1 -v v=$2 -v d=$3 'BEGIN{ v+=d; if (v>m) print v; else print m}'
}

#
# Convert E-W distance (degrees, (m)iles, or km) to (very approximate) degrees
#
xdist2deg() {
    # degreesLon = iRadius /
    #		(((cos(iStartLat * 3.141592653589 / 180) * 6076.) / 5280.) * 60)
    awk -v dist="$1" -v lat="$2" '
    BEGIN {
	PI180 = 3.1415926535 / 180.0
	num = dist; gsub(/[a-zA-Z].*/, "", num)
	if (dist ~ /[kK][mM]/) {
	    NMI2KM = 1.852
	    print num / (cos(lat*PI180) * 60 * NMI2KM)
	} else if (dist ~ /[mM]/) {
	    NMI2MI = 1.1507794
	    print num / (cos(lat*PI180) * 60 * NMI2MI)
	}
	else
	    print dist
    }'
}

#
# Convert N-S distance (degrees, (m)iles, or km) to (very approximate) degrees
#
ydist2deg() {
    awk -v dist="$1" -v lat="$2" '
    BEGIN {
	PI = 3.1415926535
	num = dist; gsub(/[a-zA-Z].*/, "", num)
	if (dist ~ /[kK][mM]/) {
	    print num*180.0 / (6378.7 * PI)
	} else if (dist ~ /[mM]/) {
	    print num*180.0 / (3963.5 * PI)
	}
	else
	    print dist
    }'
}

#
# Convert lat/lon into x/y tile coordinates for given zoom (TMS, slippy map)
# http://wiki.openstreetmap.org/wiki/SLippy_map_tilenames
#
xtile2lon() # x zoom -> lon
{
    echo "$1 $2" | awk '{
	printf("%.6f", $1 / 2.0^$2 * 360.0 - 180.0)}'
}
lon2xtile() # lon zoom -> x
{
    echo "$1 $2" | awk '{
	xtile = ($1 + 180.0) / 360.0 * 2.0^$2;
	printf("%.6f", xtile ) }'
}
ytile2lat() # y zoom -> lat
{
    echo "$1 $2" | awk -v PI=3.14159265358979323846 '{
	num_tiles = PI - 2.0 * PI * $1 / 2.0^$2;
	printf("%.6f", 180.0 / PI * atan2(0.5 * (exp(num_tiles) - exp(-num_tiles)), 1)); }'
}
lat2ytile() # lat zoom -> y
{
    echo "$1 $2" | awk -v PI=3.14159265358979323846 '{
	tan_lat=sin($1 * PI / 180.0) / cos($1 * PI / 180.0);
	ytile = (1 - log(tan_lat + 1 / cos($1 * PI / 180.0)) / PI) / 2 * 2.0^$2;
	printf("%.6f", ytile ) }'
}
ll_xy() # lat lon zoom -> x y
{
    TILE_X=`lon2xtile $2 $3`
    TILE_Y=`lat2ytile $1 $3`
    echo $TILE_X $TILE_Y
}
xy_ll() # x y zoom -> lat lon
{
    LON=`xtile2lon $1 $3`
    LAT=`ytile2lat $2 $3`
    echo $LAT $LON
}

#
#	tiger2cvt LATcenter LONcenter IW IH SCALE
#
tiger2cvt() {
    awk -F^ \
    -v CenterLat=$1 \
    -v CenterLon=$2 \
    -v ImageWidth=$3 \
    -v ImageHeight=$4 \
    -v MapScale=$5 \
    -v TITLE="$6" \
    -v FOOTER="$7" \
    -v SHOWSCALE=$SHOWSCALE \
    -v IMGDIR=$IMGDIR \
    -v Font="$MAPFONT" \
    -v TextBG="$MAPTEXTBG" \
    -v TextFG="$MAPTEXTFG" \
    -v PIXELFACT="$PIXELFACT" \
    -v IMAGEMAP="$IMAGEMAP" \
    -v OFILE="$OFILE" \
    -v LBLCOORDS="$LBLCOORDS" \
    -v DOGRID="$DOGRID" \
    '
    function gridlbl(v,		f, i)
    {
	i=int(v);
	f=(v-i)*60; if(f<0)f=-f;
	return sprintf("%d.%06.3f", i, f)
    }
    function grid1(domask, color)
    {
	lat = slat * (latd + latm/60.0)
	lon = slon * (lond + lonm/60.0)
	calcxy(lat, lon)
	if (posx < 0 || posx >= ImageWidth)
	    if (posy < 0 || posy >= ImageHeight)
		return 0
	lablen=50
	if (posy >= 0 && posy < ImageHeight)
	{
	    if (domask ~ /lines/)
		hline(posy, color, 1)
	    if (domask ~ /labels/)
	    {
		text(0, posy+5, TextFG, TextBG, Font,
		    gridlbl(lat))
		text(ImageWidth-lablen, posy+5, TextFG, TextBG, Font,
		    gridlbl(lat))
	    }
	}
	if (posx >= 0 && posx < ImageWidth)
	{
	    if (domask ~ /lines/)
		vline(posx, color, 1)
	    if (domask ~ /labels/)
	    {
		text(posx-lablen/2, 0+10, TextFG, TextBG, Font,
		    gridlbl(lon))
		text(posx-lablen/2, ImageHeight-2, TextFG, TextBG, Font,
		    gridlbl(lon))
	    }
	}
	return 1
    }
    function grid(dmins, color)
    {
	clatd = int(CenterLat)
	slat = (clatd < 0) ? -1 : 1
	clatm = slat * int((CenterLat-clatd)*60)
	clatm /= dmins; clatm = int(clatm) * dmins
	clond = int(CenterLon)
	slon = (clond < 0) ? -1 : 1
	clonm = slon * int((CenterLon-clond)*60)
	clonm /= dmins; clonm = int(clonm) * dmins

	# Lay down the grid lines first
	for (i = 0; ; i += dmins)
	{
	    latd = slat * clatd
	    lond = slon * clond
	    latm = clatm + i; while (latm >= 60) { latm -= 60; ++latd }
	    lonm = clonm + i; while (lonm >= 60) { lonm -= 60; ++lond }
	    if (!grid1("lines", color))
		break;
	}
	for (i = -dmins; ; i -= dmins)
	{
	    latd = slat * clatd
	    lond = slon * clond
	    latm = clatm + i; while (latm >= 60) { latm -= 60; ++latd }
	    lonm = clonm + i; while (lonm >= 60) { lonm -= 60; ++lond }
	    if (!grid1("lines", color))
		break;
	}
	# Now lay down the labels
	for (i = 0; ; i += dmins)
	{
	    latd = slat * clatd
	    lond = slon * clond
	    latm = clatm + i; while (latm >= 60) { latm -= 60; ++latd }
	    lonm = clonm + i; while (lonm >= 60) { lonm -= 60; ++lond }
	    if (!grid1("labels", color))
		break;
	}
	for (i = -dmins; ; i -= dmins)
	{
	    latd = slat * clatd
	    lond = slon * clond
	    latm = clatm + i; while (latm >= 60) { latm -= 60; ++latd }
	    lonm = clonm + i; while (lonm >= 60) { lonm -= 60; ++lond }
	    if (!grid1("labels", color))
		break;
	}
    }
    function calcR(lat)
    {
	# a = 6378.137, r, sc, x, y, z;
	# e2 = 0.081082 * 0.081082;
	lat = lat * M_PI_180
	sc = sin(lat)
	x = A * (1.0 - E2)
	z = 1.0 - E2 * sc * sc
	y = z ^ 1.5
	r = x / y
	return r * 1000.0
    }
    function calcxy(lat, lon)
    {
	xoff = 0; yoff = 0; zoom = 1;	# unused in this application
	posx = Ra[int(100+lat)] * M_PI_180 * cos(M_PI_180*lat) * (lon-CenterLon)
	posx = (ImageWidth/2) + posx * zoom / PixelFact - xoff
	posy = Ra[int(100+lat)] * M_PI_180 * (lat-CenterLat)
	dif = Ra[int(100+lat)] * (1 - cos(M_PI_180 * (lon-CenterLon)))
	posy = posy + dif / 1.85
	posy = (ImageHeight/2) - posy * zoom / PixelFact - xoff
    }
    function calcinit()
    {
	A = 6378.137
	E2 = 0.081082 * 0.081082
	M_PI = 3.14159265358979323846
	M_PI_180 = M_PI / 180.0
	# PIXELFACT = 2817.947378
	PixelFact = MapScale / PIXELFACT

	# Build array for earth radii
	for (i = -100; i <= 100; i++)
	    Ra[i+100] = calcR(i)
    }
    function cross(x, y, color, len)
    {
	xs = x - len
	xe = x + len - 1
	ys = y - len
	ye = y + len - 1
	printf "-fill %s ", color
	printf "-draw \"rectangle %d,%d %d,%d\" ", x-1, ys, x, ye
	printf "-draw \"rectangle %d,%d %d,%d\"\n", xs, y-1, xe, y
    }
    function circle(x, y, color, radius, thick)
    {
	printf "-strokewidth %d ", thick
	printf "-stroke %s ", color
	printf "-fill none "
	printf "-draw \"circle %d,%d %d,%d\" ", x, y, x, y+radius
	printf "-stroke none\n"
    }
    function dot(x, y, color, radius)
    {
	printf "-fill %s ", color
	printf "-draw \"circle %d,%d %d,%d\"\n", x, y, x, y+radius
    }
    function line(x1, y1, x2, y2, color, thick)
    {
	printf "-stroke %s ", color
	printf "-strokewidth %d ", thick
	printf "-fill none "
	printf "-draw \"line %d,%d %d,%d\" ", x1, y1, x2, y2
        printf "-stroke none\n"
    }
    function vline(x, color, thick)
    {
	printf "-fill %s ", color
	printf "-draw \"rectangle %d,%d %d,%d\"\n",
	    x-thick/2, 0, x+thick/2, ImageHeight-1
    }
    function hline(y, color, thick)
    {
	printf "-fill %s ", color
	printf "-draw \"rectangle %d,%d %d,%d\"\n",
	    0, y-thick/2, ImageWidth-1, y+thick/2
    }
    function xhair(x, y, color, thick)
    {
	printf "-fill %s ", color
	printf "-draw \"rectangle %d,%d %d,%d\" ",
	    0, y-thick/2, ImageWidth-1, y+thick/2
	printf "-draw \"rectangle %d,%d %d,%d\"\n",
	    x-thick/2, 0, x+thick/2, ImageHeight-1
    }
    function image(operator, x, y, filename, width, height)
    {
	squote = "\047"
	printf "-draw \"image %s %d,%d %d,%d %s%s%s\"\n",
	    operator, x, y, width, height, squote, filename, squote
    }
    function text(x, y, fgcolor, bgcolor, font, label0)
    {
	# sanitize text label: remap/remove quotes and stars
	squote = "\047"
	label = label0
	gsub("\"", "=", label)
	gsub(squote, "-", label)
	gsub("*", "", label)
	if (label == "") return;
	if (font != "")
	    printf "-font \"%s\" ", font
	if (bgcolor == "none")
	    printf "-fill \"%s\" ", fgcolor
	else
	    printf "-box \"%s\" -fill \"%s\" ", bgcolor, fgcolor
	printf "-draw \"text %d,%d %s%s%s\"\n", x, y, squote, label, squote
    }
    function barscale(x, y, dx, dy)
    {
	printf "-fill \"black\" "
	printf "-draw \"rectangle %.0f,%.0f %.0f,%.0f\" ", x, y, x+dx, y-dy
	printf "-fill \"white\" "
	printf "-draw \"rectangle %.0f,%.0f %.0f,%.0f\" ", x+0*dx/10+1, y-1, x+5*dx/10-1, y-dy+1
	printf "-draw \"rectangle %.0f,%.0f %.0f,%.0f\" ", x+6*dx/10+1, y-1, x+7*dx/10-1, y-dy+1
	printf "-draw \"rectangle %.0f,%.0f %.0f,%.0f\" ", x+8*dx/10+1, y-1, x+9*dx/10-1, y-dy+1
	printf "-fill \"none\"\n"
    }
    function imsquare(cx, cy, size, url)
    {
	if (IMAGEMAP != "")
	{
	    size /= 2
	    printf "<AREA SHAPE=\"rect\" COORDS=\"%d,%d,%d,%d\" HREF=\"%s\">\n",
		cx-size, cy-size, cx+size, cy+size, url >> usemap_file
	}
    }
    function imrect(cx, cy, w, h, url)
    {
	if (IMAGEMAP != "")
	{
	    w /= 2; h /= 2
	    printf "<AREA SHAPE=\"rect\" COORDS=\"%d,%d,%d,%d\" HREF=\"%s\">\n",
		cx-w, cy-h, cx+w, cy+h, url >> usemap_file
	}
    }
    function imcircle(cx, cy, radius, url)
    {
	if (IMAGEMAP != "")
	{
	    printf "<AREA SHAPE=\"circle\" COORDS=\"%d,%d,%d\" HREF=\"%s\">\n",
		cx, cy, radius, url >> usemap_file
	}
    }

    BEGIN {
	calcinit()
	colors["red"] = "red"; colors["grn"] = "green"; colors["blu"] = "blue";
	colors["org"] = "orange"; colors["pur"] = "purple";
	colors["mag"] = "magenta"; colors["brn"] = "brown";
	colors["lgr"] = "lightgreen"; colors["cyn"] = "cyan";
	colors["gry"] = "gray"; colors["wht"] = "white";
	colors["yel"] = "yellow";
	if (IMAGEMAP != "")
	{
	    usemap_tag = OFILE
	    sub("[.].*", "", usemap_tag)
	    sub(".*[/]", "", usemap_tag)
	    usemap_file = IMAGEMAP
	    usemap_append = 0
	    if (IMAGEMAP ~ /^[+]/) {
		sub("^[+]", "", usemap_file)
		usemap_append = 1
	    }
	}
	if (DOGRID != "0")
	{
	    dmins = DOGRID
	    sub(",.*", "", dmins);
	    if (dmins ~ /[mM]/)
		sub("[mM]", "", dmins);
	    if (dmins ~ /[dD]/)
	    {
		sub("[dD]", "", dmins);
		dmins *= 60
	    }

	    if (DOGRID ~ /,/)
	    {
		color = DOGRID
		sub(".*,", "", color);
	    }
	    else
		color = "red"
	    
	    grid(dmins, color);
	}
    }
    END {
	if (TITLE != "")
		text(0, 0+10, TextFG, TextBG, Font, TITLE)
	if (FOOTER != "")
		text(0, ImageHeight-2, TextFG, TextBG, Font, FOOTER)
	if (SHOWSCALE != 0)
	{
	    distance=10000
	    distunit="km"
	    distfact=1000
	    if (SHOWSCALE == 2)
	    {
		distunit="mi"
		distfact=1609.344
	    }
	    barlength=PIXELFACT/MapScale*distance*distfact
	    # shrink bar to <=1/10 width; {1,2,5}*10^x
	    while (barlength > ImageWidth)
	    {
		distance/=10; barlength/=10
	    }
	    if (barlength > ImageWidth/2)
	    {
		distance/=5; barlength/=5
	    }
	    else if (barlength > ImageWidth/5)
	    {
		distance/=2; barlength/=2
	    }
	    text(ImageWidth-5-int(barlength)/2-20, ImageHeight-13, TextFG, TextBG, Font,
		" " distance " " distunit " ")
	    barscale(ImageWidth-5-int(barlength), ImageHeight-5, int(barlength), 5)
	}
    }
    /^#/ { next }
    {
	# Tiger style...
	# -97.604630,46.919800:reddot10:RetributionTrail
	# -97.938850,46.548900:reddot10:FortRansomStatePark
	lonlat = $1; split(lonlat, coord, ","); lat = coord[2]; lon = coord[1]
	symbol = $2
	label = $3
	url = $4
	lllabel = $5
	oposx = posx
	oposy = posy

	# next line converts a backquote to a single quote in the label
	squote = "\047"; gsub("`", squote, label)

	calcxy(lat, lon)

	n = split(symbol, symatt, /,/)

	if (symatt[1] != "circle")
	{
	    # Clip everything except circles that are not centered on the image
	    if (posx < 0 || posx >= ImageWidth) next;
	    if (posy < 0 || posy >= ImageHeight) next;
	}

	if (n == 1 && symatt[1] == "gc")
	{
	    radius = int(PIXELFACT * 0.1 * 1609.344 / MapScale + 0.5)
	    circle(posx, posy, "red", radius, 1)
	    cross(posx, posy, "red", 10)
	    imcircle(posx, posy, radius, url)
	}
	else if (n == 1 && symatt[1] == "gcbw")
	{
	    radius = int(PIXELFACT * 0.1 * 1609.344 / MapScale + 0.5)
	    circle(posx, posy, "white", radius, 1)
	    cross(posx, posy, "white", 10)
	    imcircle(posx, posy, radius, url)
	}
	else if (n == 1 && symatt[1] == "puzzle")
	{
	    radius = int(PIXELFACT * 2.0 * 1609.344 / MapScale + 0.5)
	    circle(posx, posy, "red", radius, 1)
	    cross(posx, posy, "red", 10)
	    imcircle(posx, posy, radius, url)
	}
	else if (n == 3)
	{
	    if (symatt[1] ~ /\.gif$|\.jpg$|\.png$/)
	    {
		# imagefile,xsize,ysize
		xsize = symatt[2]
		ysize = symatt[3]
		image("Over", posx-xsize/2, posy-ysize/2,
			 symatt[1], xsize, ysize)
		imrect(posx, posy, xsize, ysize, url)
		posx += xsize/2 + 2
	    }
	    else if (symatt[1] == "cross")
	    {
		# cross,color,size
		cross(posx, posy, symatt[2], symatt[3])
		imsquare(posx, posy, symatt[3], url)
		posx += 2
		posy -= 8
	    }
	    else if (symatt[1] == "circle")
	    {
		# circle,color,radius
		radius = symatt[3]
		if (radius ~ /[kK][mM]$/)
		{
		    # radius in kilometers
		    sub("[kK][mM]", "", radius)
		    radius = int(PIXELFACT * radius * 1000 / MapScale + 0.5)
		}
		else if (radius ~ /[mM]$/)
		{
		    # radius in meters
		    sub("[mM]", "", radius)
		    radius = int(PIXELFACT * radius / MapScale + 0.5)
		}
		else if (radius ~ /[mM][iI]$/)
		{
		    # radius in miles
		    sub("[mM][iI]", "", radius)
		    radius = int(PIXELFACT * radius * 1609.344 / MapScale + 0.5)
		}
		else if (radius ~ /[fF][tT]$/)
		{
		    # radius in feet
		    sub("[fF][tT]", "", radius)
		    radius = int(PIXELFACT * radius * 0.3048 / MapScale + 0.5)
		}
		circle(posx, posy, symatt[2], radius, 1)
		imcircle(posx, posy, radius, url)
		label=""
	    }
	    else if (symatt[1] == "dot")
	    {
		# dot,color,diameter
		diameter = symatt[3]
		dot(posx, posy, symatt[2], diameter/2)
		imcircle(posx, posy, diameter/2, url)
		posx += diameter/2 + 2
	    }
	    else if (symatt[1] == "vline")
	    {
		# vline,color,thick
		thick = symatt[3]
		cross(posx, posy, symatt[2], 8)
		imsquare(posx, posy, 8, url)
		vline(posx, symatt[2], thick)
		posx += 8 + 2
	    }
	    else if (symatt[1] == "hline")
	    {
		# hline,color,thick
		thick = symatt[3]
		cross(posx, posy, symatt[2], 8)
		imsquare(posx, posy, 8, url)
		hline(posy-1, symatt[2], thick)
		posx += 1
		posy -= 8+thick/2
	    }
	    else if (symatt[1] == "xhair")
	    {
		# xhair,color,thick
		thick = symatt[3]
		imsquare(posx, posy, 8, url)
		xhair(posx, posy-1, symatt[2], thick)
		posx += 8 + 2
		posy -= 8+thick/2
	    }
	    else if (symatt[1] == "line")
	    {
		# line,color,thick
		thick = symatt[3]
		imsquare(posx, posy, 8, url)
		line(oposx, oposy, posx, posy-1, symatt[2], thick)
		#posx += 8 + 2
		#posy -= 8+thick/2
	    }
	}
	else if (n == 4)
	{
	    if (symatt[1] == "circle")
	    {
		# circle,color,radius,thick
		radius = symatt[3]
		if (radius ~ /[mM]$/)
		{
		    # radius in meters
		    sub("[mM]", "", radius)
		    radius = int(PIXELFACT * radius / MapScale + 0.5)
		}
		circle(posx, posy, symatt[2], radius, symatt[4])
		imcircle(posx, posy, radius, url)
		label=""
	    }
	}
	else if (n == 5)
	{
	    if (symatt[1] ~ /\.gif$|\.jpg$|\.png$/)
	    {
		# imagefile,xsize,ysize,xoff,yoff
		xsize = symatt[2]
		ysize = symatt[3]
		xoff = symatt[4]
		yoff = symatt[5]
		image("Over", posx-xsize/2+xoff, posy-ysize/2+yoff,
			 symatt[1], xsize, ysize)
		imrect(posx+xoff, posy+yoff, xsize, ysize, url)
		posx += xsize/2 + 2 + xoff
		posy += yoff
	    }
	}
	else if (symatt[1] ~ /\.gif$|\.jpg$|\.png$/)
	{
	    image("Over", posx, posy, symbol, 0, 0)
	    imsquare(posx, posy, 24, url)
	}
	else if (symatt[1] ~ /^[Gg]eocache-/)
	{
	    img = symatt[1];
	    sub("-unavail", "", img)
	    sub("-soc", "", img)
	    sub("-kb", "", img)
	    image("Over", posx-12, posy-12,
		    IMGDIR "/" tolower(img) ".gif", 0, 0)
	    if (symatt[1] ~ /-unavail/)
		image("Over", posx-12, posy-12,
		    IMGDIR "/geocache-unavail.gif", 0, 0)
	    imsquare(posx, posy, 24, url)
	    posx += 24/2 + 2
	}
	else
	{
	    if (symbol == "greenpin") symbol = "grnpin"	# just for RJL
	    colstr = substr(symbol, 1, 3)
	    color = colors[colstr]
	    if (color == "") color = colstr
	    symstr = substr(symbol, 4, 3)
	    symsize = substr(symbol, 7, 2)
	    if (symsize == 0) symsize = 10
	    symsize += 0

	    if (symbol=="bluestar" || symbol=="redstar" || symbol=="cross")
	    {
		image("Over", posx-19/2, posy-19/2,
			IMGDIR "/" symbol ".gif", 0, 0)
		imsquare(posx, posy, 19, url)
		posx += 19/2 + 2
	    }
	    else if (symstr == "dot")
	    {
		# e.g. reddot10
		dot(posx, posy, color, symsize/2)
		imcircle(posx, posy, symsize/2, url)
		posx += symsize/2 + 2
	    }
	    else if (symstr == "pin")
	    {
		# e.g. redpin
		# TODO: handle transparency
		image("Over", posx, posy-16, IMGDIR "/" symbol ".gif", 0, 0)
		imsquare(posx, posy, 16, url)
		posx += 16 + 2
		posy -= 5+4
	    }
	    else if (symstr != "")
	    {
		# unknown symbol, use default
		# cross,color,size
		cross(posx, posy, "red", 6)
		imsquare(posx, posy, 6, url)
		posx += 2
		posy -= 8
	    }
	}

	if (LBLCOORDS && label != lllabel)
	{
	    if (label == ".")
	    {
		label = lllabel;
		sub(/ .*/, "", label)
		sub(/.*[.]/, ".", label)
		sub(/.* /, "", lllabel)
		sub(/.*[.]/, ".", lllabel)
	    }
	    text(posx, posy+5, TextFG, TextBG, Font, label)
	    text(posx, posy+18, TextFG, TextBG, Font, lllabel)
	}
	else
	    text(posx, posy+5, TextFG, TextBG, Font, label)
    }
    '
}

#
#	A temporary style for processing waypoint files.
#
make_temp_style() {
    CRUFT="$CRUFT $1"
    cat <<-EOF > $1
	ENCODING		UTF-8 
	FIELD_DELIMITER		|
	RECORD_DELIMITER        NEWLINE
	BADCHARS                |
	IFIELD	LAT_DECIMAL,	"",	"%.6f"
	IFIELD	LON_DECIMAL,	"",	"%.6f"
	IFIELD	ICON_DESCR,	"",	"%s"
	IFIELD	DESCRIPTION,	"",	"%s"
	IFIELD	URL,		"",	"%s"
	EOF
}

make_short_temp_style() {
    CRUFT="$CRUFT $1"
    cat <<-EOF > $1
	ENCODING		UTF-8 
	FIELD_DELIMITER		|
	RECORD_DELIMITER        NEWLINE
	BADCHARS                |
	IFIELD	LAT_DECIMAL,	"",	"%.6f"
	IFIELD	LON_DECIMAL,	"",	"%.6f"
	IFIELD	ICON_DESCR,	"",	"%s"
	IFIELD	SHORTNAME,	"",	"%s"
	IFIELD	URL,		"",	"%s"
	EOF
}

#
#	Process title escapes
#
title_escapes() {
    echo "$1" | sed \
	-e "s/%A/$CMDLINE/" \
	-e "s/%a/$CMDLINE2/" \

}

#
#       Set default options, can be overriden on command line or in rc file
#
MAPWIDTH=1280
MAPHEIGHT=1024
MAPSCALE=10K
MAPSRC=osm
MAPSRC=gmap
MAPSRC=leaflet
MAPFONT=${MAPFONT:-}
MAPTEXTBG=${MAPTEXTBG:-white}		#Can also use #rrggbbaa
MAPTEXTFG=${MAPTEXTFG:-black}		#Can also use #rrggbbaa

UPDATE_URL=$WEBHOME/geo-map
UPDATE_FILE=geo-map.new

read_rc_file

#
#	Process stdin if number of args is zero
#
if [ $# = 0 ]; then
    echo "Type the geo-map command line(s): "
    while read a; do
	geo-map -- $a
	sleep 1
    done
    exit
fi

#
#       Process the options
#
CMDLINE=$(echo -- "$@" | sed -e 's@/@\\/@g')
ARGS="$@"
TIGER=
IMAGEMAP=
SMALL=0
MARKER=1
LABEL=
OFILE=
DOWWW=0
VERBOSE=1
LBLCOORDS=0
MINRADIUS=
MAXRADIUS=
DOGRID=0
TITLE=
FOOTER=
SHOWSCALE=0
JOG=
POLY=
CENTER_1ST=0
SYMBOL=cross,red,10
DEFSYMBOL=
while getopts "a:cCg:h:ik:mr:R:s:S:t:j:T:F:BbW:H:o:P:D:U?-" opt
do
	case $opt in
	a)	MAPSRC="$OPTARG";;
	c)	LBLCOORDS=1;;
	C)	CENTER_1ST=1;;
	g)	DOGRID="$OPTARG";;
	h)	IMAGEMAP="$OPTARG";;
	i)	SMALL=1;;
	k)	GMAP_KEY="$OPTARG";;
	m)	MARKER=0;;
	o)	OFILE="$OPTARG"; VERBOSE=0;
		case "$OFILE" in
		www|http)
		    OFILE=/tmp/111.jpg;  DOWWW=1
		    ;;
		www:*|http:*)
		    OFILE=/tmp/$(echo $OFILE | sed 's/.*://');  DOWWW=1
		    ;;
		esac
		case "$OFILE" in
		*.*)	;;
		*)	OFILE="$OFILE.jpg";;
		esac
		;;
	r)	MINRADIUS="$OPTARG";;
	R)	MAXRADIUS="$OPTARG";;
	s)	MAPSCALE="$OPTARG";;
	S)	DEFSYMBOL="$OPTARG"; SYMBOL="$DEFSYMBOL";;
	t)	TIGER="$OPTARG";;
	T)	TITLE="$OPTARG";;
	F)	FOOTER="$OPTARG";;
	B)	SHOWSCALE=1;; #km
	b)	SHOWSCALE=2;; #mi
	j)	JOG="$OPTARG";;
	W)	MAPWIDTH="$OPTARG";;
	H)	MAPHEIGHT="$OPTARG";;
	P)	POLY="$OPTARG";;
	D)	DEBUG="$OPTARG";;
	U)	echo "Getting latest version of this script..."
		curl $CURL_OPTS -o$UPDATE_FILE "$UPDATE_URL"
		chmod +x "$UPDATE_FILE"
		echo "Latest version is in $UPDATE_FILE"
		exit
		;;
	\?|-)	usage;;
	esac
done
shift `expr $OPTIND - 1`

if [ "$OFILE" = "" -a "$IMAGEMAP" != "" ]; then
    error "Option -h also requires option -o"
fi
if [ "$TIGER" = "" -a "$IMAGEMAP" != "" ]; then
    error "Option -h also requires option -t"
fi

if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi

CMDLINE2=$(echo -- "$@" | sed -e 's@/@\\/@g')
TITLE=$(title_escapes "$TITLE")
FOOTER=$(title_escapes "$FOOTER")

#
#	Walk the command line args and place them into arrays
#
LATcenter=
LONcenter=
Npts=0
LATmin=999; LATmax=-999
LONmin=999; LONmax=-999
while [ $# -ge 2 ]; do
    case "$1" in
    N|S)
	if [ $# -ge 6 ]; then
	    # Allow cut and paste from geocaching.com cache page
	    # N 44° 58.630 W 093° 09.310
	    LAT=`echo "$1$2.$3" | tr -d '\260\302\272' `
	    LAT=`latlon $LAT`
	    LON=`echo "$4$5.$6" | tr -d '\260\302\272' `
	    LON=`latlon $LON`
	    shift 6
	else
	    error "Illegal lat/lon: $*"
	fi
	;;
    *)
	LAT=`latlon $1`
	LON=`latlon $2`
	shift 2
	;;
    esac

    #
    #	Default label and symbol
    #
    LABEL=""
    if [ $SMALL -eq 0 ]; then
	LABEL="`degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
    fi
    #
    #	Determine if user has supplied a label and symbol
    # 
    if [ "$#" -ge 1 ]; then
	if ! is_latlon "$@"; then
	    if [ "$1" != "@" ]; then
		LABEL="$1"
	    fi
	    shift

	    if [ "$#" -ge 1 ]; then
		if ! is_latlon "$@"; then
		    if [ "$1" != "@" ]; then
			SYMBOL="$1"
			unpack_images "$SYMBOL"
		    fi
		    shift
		fi
	    fi
	fi
    fi

    Lat[Npts]="$LAT"
    Lon[Npts]="$LON"
    Label[Npts]="$LABEL"
    Symbol[Npts]="$SYMBOL"
    Url[Npts]="NONE"
    LLlabel[Npts]=""
    if [ $SMALL -eq 0 ]; then
	LLlabel[Npts]="`degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
    fi
    ((++Npts))
done
# now calculate min/max lat/lon
LATmin=`
i=0
while ((i < Npts)); do
    echo ${Lat[i]}; ((++i))
done | awk -vM=$LATmin '{if($1<M)M=$1}END{print M}'
`
LATmax=`
i=0
while ((i < Npts)); do
    echo ${Lat[i]}; ((++i))
done | awk -vM=$LATmax '{if($1>M)M=$1}END{print M}'
`
LONmin=`
i=0
while ((i < Npts)); do
    echo ${Lon[i]}; ((++i))
done | awk -vM=$LONmin '{if($1<M)M=$1}END{print M}'
`
LONmax=`
i=0
while ((i < Npts)); do
    echo ${Lon[i]}; ((++i))
done | awk -vM=$LONmax '{if($1>M)M=$1}END{print M}'
`

#
#	Check parms for overlay of an existing map
#
case "$MAPSRC" in
*.gif|*.png)
	if [ "${Lat[0]}" = "" ]; then
	    error "Must supply center coord of existing map on command line"
	fi
	if [ "$MAPSCALE" = 0 ]; then
	    error "Cannot autoscale an existing map"
	fi
	;;
esac

#
#	If there is a tiger data file, then the command line coordinate
#	is the center of the desired map and is not plotted.  If there
#	is no command line coordinate, then the center of the map is
#	the center of the bounding box of the tiger waypoints.  In any
#	case, read the tiger data into our arrays.
#
if [ "$TIGER" != "" ]; then
    if [ ! -f "$TIGER" ]; then
	error "Tiger file '$TIGER'  doesn't exist."
    fi
    if [ ! -s "$TIGER" ]; then
	error "Tiger file '$TIGER' is empty."
    fi
    if [ $Npts -ge 1 ]; then
	LATcenter=`awk -v v1=$LATmin -v v2=$LATmax 'BEGIN{print (v1+v2)/2}'`
	LONcenter=`awk -v v1=$LONmin -v v2=$LONmax 'BEGIN{print (v1+v2)/2}'`
    fi

    #
    # Figure out what kind of waypont file we have
    #
    read hdr < $TIGER

    IFMT=
    case "$hdr" in
    *tms-marker*)
	#
	# The gpsbabel tiger file reader throws away the icon name,
	# so we must process this file type "by hand".
	#
	OIFS="$IFS"
	IFS=":"
	goturl=0
	while read coord SYMBOL LABEL URL
	do
	    case "$coord" in
	    "#"*) continue;;
	    esac
	    LON=${coord%%,*}
	    LAT=${coord##*,}

	    unpack_images "$SYMBOL"

	    Lat[Npts]="$LAT"
	    Lon[Npts]="$LON"
	    # rer fix: 02/12/16
	    Label[Npts]="${LABEL//\'/\\\'}"
	    Symbol[Npts]="$SYMBOL"
	    if [ "$DEFSYMBOL" != "" ]; then
		Symbol[Npts]="$DEFSYMBOL"
	    fi
	    Url[Npts]="$URL"
	    LLlabel[Npts]=""
	    if [ $SMALL -eq 0 ]; then
		LLlabel[Npts]="`degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
	    fi
	    ((++Npts))
	    if [ "$URL" != "" ]; then
		goturl=1
	    fi
	done < $TIGER
	IFS="$OIFS"
	if [ $goturl = 0 -a "$IMAGEMAP" != "" ]; then
	    error "Cannot make image map with this tiger file (No URLs!)"
	fi
	;;
    \#\#*)
	#
	# geo-mystery file
	#
	while read GCID LAT LON LABEL
	do
	    case "$GCID" in
	    G*)		;;
	    *)		continue;;
	    esac
	    case "$LAT" in
	    unk)	continue;;
	    esac

	    SYMBOL=
	    LAT=`latlon $LAT`
	    LON=`latlon $LON`

	    Lat[Npts]="$LAT"
	    Lon[Npts]="$LON"
	    # rer fix: 02/12/16
	    Label[Npts]="$GCID ${LABEL//\'/\\\'}"
	    Symbol[Npts]="$SYMBOL"
	    if [ "$DEFSYMBOL" != "" ]; then
		Symbol[Npts]="$DEFSYMBOL"
	    elif [ "$SYMBOL" == "" ]; then
		Symbol[Npts]="cross,red,10"
	    fi
	    Url[Npts]="$URL"
	    LLlabel[Npts]="`degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
	    if [ $SMALL -ne 0 ]; then
		LLlabel[Npts]=""
	    fi
	    ((++Npts))
	done < $TIGER
	verbose 1 "Count is $Npts"
	;;
    "GEOCACHE PUZZLE"*)
	#
	# GEOCACHE PUZZLE ...
	#
	OIFS="$IFS"
	IFS="	"
	while read GCID LABEL LAT LON xtra
	do
	    case "$GCID" in
	    "GC NUMBER")	continue;;
	    GC*)		;;
	    *)			continue;;
	    esac
	    case "$LAT" in
	    unk)	continue;;
	    esac

	    SYMBOL=
	    LAT=`echo "$LAT" | tr -d '\302\260' | sed 's/ /./' `
	    LON=`echo "$LON" | tr -d '\302\260' | sed 's/ /./' `
	    LAT=`latlon $LAT`
	    LON=`latlon $LON`

	    Lat[Npts]="$LAT"
	    Lon[Npts]="$LON"
	    # rer fix: 02/12/16
	    Label[Npts]="$GCID ${LABEL//\'/\\\'}"
	    Symbol[Npts]="$SYMBOL"
	    if [ "$DEFSYMBOL" != "" ]; then
		Symbol[Npts]="$DEFSYMBOL"
	    elif [ "$SYMBOL" == "" ]; then
		Symbol[Npts]="cross,red,10"
	    fi
	    Url[Npts]="$URL"
	    LLlabel[Npts]="`degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
	    if [ $SMALL -ne 0 ]; then
		LLlabel[Npts]=""
	    fi
	    ((++Npts))
	done < $TIGER
	IFS="$OIFS"
	verbose 1 "Count is $Npts"
	;;
    *\	*)	IFMT=tabsep ;;
    "<?xml"*)
	{ read hdr; read hdr2; } < $TIGER
	case "$hdr2" in
	"<gpx"*)	IFMT=gpx;;
	"<loc"*)	IFMT=geo;;
	*)		error "Don't know what file this is.  GPX? LOC?";;
	esac
	;;
    *)
	error "Cannot handle this format, use tiger, tabsep or GPX"
	;;
    esac

    #
    #	Process reasonable formats generically
    #
    if [ "$IFMT" != "" ]; then
	#
	# Convert the waypoint file to our temporary format
	#
	TMPSTYLE=${TMP}-style.tmp
	if [ $SMALL -ne 0 ]; then
	    make_short_temp_style $TMPSTYLE
	else
	    make_temp_style $TMPSTYLE
	fi
	TMPWAY=${TMP}-way.tmp
	CRUFT="$CRUFT $TMPWAY"

	gpsbabel -i $IFMT -f $TIGER -o xcsv,style=$TMPSTYLE -F $TMPWAY

	#
	# Now read the waypoints into shell arrays
	#
	OIFS="$IFS"
	IFS="|"
	while read LAT LON SYMBOL LABEL URL
	do
	    if [ $SMALL -ne 0 ]; then
		case "$SYMBOL" in
		    Geocache-ifound*)	SYMBOL="grydot";;
		    Geocache-regular)	SYMBOL="grndot";;
		    Geocache-multi)	SYMBOL="orgdot";;
		    Geocache-unavail*)	SYMBOL="whtdot";;
		    Geocache-unfound*)	SYMBOL="reddot";;
		    Geocache-*)		SYMBOL="bludot";;
		esac
	    fi

	    unpack_images "$SYMBOL"

	    Lat[Npts]="$LAT"
	    Lon[Npts]="$LON"
            # rer fix: 02/12/16
            Label[Npts]="$GCID ${LABEL//\'/\\\'}"
	    Symbol[Npts]="$SYMBOL"
	    if [ "$DEFSYMBOL" != "" ]; then
		Symbol[Npts]="$DEFSYMBOL"
	    elif [ "$SYMBOL" == "" ]; then
		Symbol[Npts]="cross,red,10"
	    fi
	    Url[Npts]="$URL"
	    LLlabel[Npts]="`degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
	    if [ $SMALL -ne 0 ]; then
		LLlabel[Npts]=""
	    fi
	    ((++Npts))
	done < $TMPWAY
	IFS="$OIFS"
    fi

    if [ $Npts -lt 1 ]; then
	error "No waypoints to plot!"
    fi

    # recalculate min/max lat/lon
    LATmin=`
    i=0
    while ((i < Npts)); do
	echo ${Lat[i]}; ((++i))
    done | awk -vM=$LATmin '{if($1<M)M=$1}END{print M}'
    `
    LATmax=`
    i=0
    while ((i < Npts)); do
	echo ${Lat[i]}; ((++i))
    done | awk -vM=$LATmax '{if($1>M)M=$1}END{print M}'
    `
    LONmin=`
    i=0
    while ((i < Npts)); do
	echo ${Lon[i]}; ((++i))
    done | awk -vM=$LONmin '{if($1<M)M=$1}END{print M}'
    `
    LONmax=`
    i=0
    while ((i < Npts)); do
	echo ${Lon[i]}; ((++i))
    done | awk -vM=$LONmax '{if($1>M)M=$1}END{print M}'
    `

    #
    #	Compute the center
    #
    if [ "$LATcenter" = "" ]; then
	LATcenter=`awk -v v1=$LATmin -v v2=$LATmax 'BEGIN{print (v1+v2)/2}'`
	LONcenter=`awk -v v1=$LONmin -v v2=$LONmax 'BEGIN{print (v1+v2)/2}'`
    fi
else
    if [ $Npts -lt 1 ]; then
	error "Must supply at least one coordinate on the command line"
    elif [ $Npts -gt 1 -a $CENTER_1ST = 0 ]; then
	LATcenter=`awk -v v1=$LATmin -v v2=$LATmax 'BEGIN{print (v1+v2)/2}'`
	LONcenter=`awk -v v1=$LONmin -v v2=$LONmax 'BEGIN{print (v1+v2)/2}'`
    else
	LATcenter="${Lat[0]}"
	LONcenter="${Lon[0]}"
    fi
fi

#
#	Determine scaling
#
#	Magic number explanation: 2817.947378 is pixels per meter and
#	MAPSCALE/2817.947378 is therefore in units of meters / pixel.
#
#	Assuming maps rendered at 72DPI, the nominal value should be
#	72 * 39.370079 = 2834.6459.  But 2817.947378 is what GpsDrive
#	uses.  Presumably its tuned to the mapblast source, but who knows.
#
PIXELFACT=2817.947378
case "$MAPSRC" in
6|gc|7|gc-icons)
	# Don't know how to change the size of these maps
	#
	# In addition, as of 11/2/03, these maps are mis-scaled.
	# The maps are delivered with 400x350 resolution, but should
	# be displayed at 400x500 if you want equal X/Y scaling!
	# We stretch the maps later to account for this.
	MAPWIDTH=400
	MAPHEIGHT=500
	PIXELFACT=`echo "100 39.370079 *p" | dc`
	;;
8|multimap)	
	PIXELFACT=`echo "96 39.370079 *p" | dc`
	# Size must be less than 800x600...
	if [ "$MAPWIDTH" -gt 800 ]; then MAPWIDTH=800; fi
	if [ "$MAPHEIGHT" -gt 700 ]; then MAPHEIGHT=700; fi
	;;
9|multimap-aerial)
	PIXELFACT=`echo "96 39.370079 *p" | dc`
	# There are only two sizes of these...
	if [ "$MAPWIDTH" -gt 500 ]; then MAPWIDTH=700; fi
	if [ "$MAPWIDTH" -lt 500 ]; then MAPWIDTH=500; fi
	if [ "$MAPHEIGHT" -gt 300 ]; then MAPHEIGHT=400; fi
	if [ "$MAPHEIGHT" -lt 300 ]; then MAPHEIGHT=300; fi
	if [ "$MAPWIDTH" = 700 ]; then MAPHEIGHT=400; fi
	if [ "$MAPHEIGHT" = 400 ]; then MAPWIDTH=700; fi
	;;
12|natgeo|ng)
	# Fixed image size
	MAPWIDTH=645
	MAPHEIGHT=420
	PIXELFACT=700		# Pure guess
	;;
13|ts*|citipix|globex*)
	# Fixed image size
	MAPWIDTH=500
	MAPHEIGHT=500
	;;
esac

#
# Adjust mapscale units
#
case "$MAPSCALE" in
*[Kk])	MAPSCALE=`echo $MAPSCALE | sed 's/[Kk]/ 1000*p/' | dc`;;
*[Mm])	MAPSCALE=`echo $MAPSCALE | sed 's/[Mm]/ 1000000*p/' | dc`;;
*mpp)	MAPSCALE=$(awk "BEGIN{ s = $MAPSCALE; sub(/mpp/, //, s);
			print int(s*$PIXELFACT)}");;
*fpp)	MAPSCALE=$(awk "BEGIN{ s = $MAPSCALE; sub(/fpp/, //, s);
			print int(s*$PIXELFACT*.3048)}");;
*ftpp)  MAPSCALE=$(awk "BEGIN{ s = $MAPSCALE; sub(/ftpp/, //, s);
			print int(s*$PIXELFACT*.3048)}");;
*ft)	MAPSCALE=$(awk "BEGIN{ s = $MAPSCALE; sub(/ft/, //, s);
			print int(s*$PIXELFACT*.3048)}");;
*f)	MAPSCALE=$(awk "BEGIN{ s = $MAPSCALE; sub(/f/, //, s);
			print int(s*$PIXELFACT*.3048)}");;
*ipp)	MAPSCALE=$(awk "BEGIN{ s = $MAPSCALE; sub(/ipp/, //, s);
			print int(s*$PIXELFACT*.0254)}");;
*in)	MAPSCALE=$(awk "BEGIN{ s = $MAPSCALE; sub(/in/, //, s);
			print int(s*$PIXELFACT*.0254)}");;
esac

if [ "$MAPSCALE" = 0 ]; then
    # Compute center
    LATcenter=`awk -v v1=$LATmin -v v2=$LATmax 'BEGIN{print (v1+v2)/2}'`
    LONcenter=`awk -v v1=$LONmin -v v2=$LONmax 'BEGIN{print (v1+v2)/2}'`
    if [ "$MINRADIUS" != "" ]; then
	# Enforce minimum "radius"
	LATR=$(ydist2deg $MINRADIUS)
	LONR=$(xdist2deg $MINRADIUS $LATcenter)
	debug 2 "LATR=$LATR LONR=$LONR"
	LATmin=$(fmindelta $LATmin $LATcenter $LATR)
	LONmin=$(fmindelta $LONmin $LONcenter $LONR)
	LATmax=$(fmaxdelta $LATmax $LATcenter $LATR)
	LONmax=$(fmaxdelta $LONmax $LONcenter $LONR)
    fi
    if [ "$MAXRADIUS" != "" ]; then
	# Enforce maximum "radius"
	LATR=$(ydist2deg $MAXRADIUS)
	LONR=$(xdist2deg $MAXRADIUS $LATcenter)
	debug 2 "LATR=$LATR LONR=$LONR"
	LATmin=$(fmaxdelta $LATmin $LATcenter -$LATR)
	LONmin=$(fmaxdelta $LONmin $LONcenter -$LONR)
	LATmax=$(fmindelta $LATmax $LATcenter -$LATR)
	LONmax=$(fmindelta $LONmax $LONcenter -$LONR)
    fi
    MAPSCALE=`calc_scale $LATmin $LONmin $LATmax $LONmax $MAPWIDTH $MAPHEIGHT`
    debug 1 "Map scale is:  $MAPSCALE"
    debug 2 "Center:  $LATcenter,$LONcenter"
    debug 2 "Corners:  $LATmin,$LONmin  $LATmax,$LONmax"
fi

if [ "" != "$JOG" ]; then
    case "$JOG" in
    *,*)
	    dir=$(echo "$JOG" | sed 's/,.*//')
	    amt=$(echo "$JOG" | sed 's/.*,//')
	    ;;
    *)	    dir="$JOG"; amt=0.8;;
    esac
    latm=`echo "$MAPSCALE $MAPHEIGHT * $amt*2/ $PIXELFACT /p" | dc`
    lonm=`echo "$MAPSCALE $MAPWIDTH * $amt*2/ $PIXELFACT /p" | dc`
    # lon=`calc_latlon lon $LATcenter $LONcenter $meters 90`
    case "$dir" in
    s|S)	LATcenter=`calc_latlon lat $LATcenter $LONcenter $latm 0`;;
    n|N)	LATcenter=`calc_latlon lat $LATcenter $LONcenter $latm 180`;;
    w|W)	LONcenter=`calc_latlon lon $LATcenter $LONcenter $lonm 90`;;
    e|E)	LONcenter=`calc_latlon lon $LATcenter $LONcenter $lonm 270`;;
    sw|SW)	LATcenter=`calc_latlon lat $LATcenter $LONcenter $latm 0`
		LONcenter=`calc_latlon lon $LATcenter $LONcenter $lonm 90`;;
    nw|NW)	LATcenter=`calc_latlon lat $LATcenter $LONcenter $latm 180`
		LONcenter=`calc_latlon lon $LATcenter $LONcenter $lonm 90`;;
    se|SE)	LATcenter=`calc_latlon lat $LATcenter $LONcenter $latm 0`
		LONcenter=`calc_latlon lon $LATcenter $LONcenter $lonm 270`;;
    ne|NE)	LATcenter=`calc_latlon lat $LATcenter $LONcenter $latm 180`
		LONcenter=`calc_latlon lon $LATcenter $LONcenter $lonm 270`;;
    esac
fi

#
#	Main Program
#

IMAP=${TMP}-imap.png
OMAP=${TMP}-map.png
CRUFT="$CRUFT $IMAP"
CRUFT="$CRUFT $OMAP"

w="$MAPWIDTH"
h="$MAPHEIGHT"
GOTFMT=gif
case "$MAPSRC" in
1|mapblast|vicinity)
    debug 0 "BROKEN: this source is temporarily/permanently out of order"
    URL="http://www.vicinity.com/gif"
    URL="$URL?&CT=$LATcenter:$LONcenter:$MAPSCALE&IC=&W=$w&H=$h&FAM=myblast&LB="
    verbose 1 "$URL"
    # curl -L -s -A "$UA" "$URL" > $IMAP
    # Hmm, wget is faster here.  Dunny why.
    wget -q -U "$UA" -O $IMAP "$URL"
    ;;

2|expedia)
    # Change from XXX:1 scaling to altitude scale rounding down
    alti=`awk -v s=$MAPSCALE 'BEGIN { printf "%d", s/3950.0 }'`
    debug 1 "scale=$MAPSCALE, alti=$alti"
    # and back again...
    if [ $alti -eq 0 ]; then
	alti=1
    fi
    ((EXPSCALE=alti*3950))
    ww=`echo $MAPWIDTH  $MAPSCALE $EXPSCALE | awk '{printf("%.0f",$1*$2/$3)}'`
    hh=`echo $MAPHEIGHT $MAPSCALE $EXPSCALE | awk '{printf("%.0f",$1*$2/$3)}'`
    while [ $ww -gt 2000 -o $hh -gt 2000 ]
    do
	alti=`expr $alti + 1`
	((EXPSCALE=alti*3950))
	ww=`echo $MAPWIDTH  $MAPSCALE $EXPSCALE | awk '{printf("%.0f",$1*$2/$3)}'`
	hh=`echo $MAPHEIGHT $MAPSCALE $EXPSCALE | awk '{printf("%.0f",$1*$2/$3)}'`
    done
    debug 1 "scale=$EXPSCALE, alti=$alti"
    lang=`awk -v v=$LONcenter 'BEGIN{ print (v>-20) ? "EUR0809" : "USA0409"}'`
    URL="http://www.expedia.com/pub/agent.dll"
    URL="$URL?qscr=mrdt&ID=3XNsF.&CenP=$LATcenter,$LONcenter"
    URL="$URL&Lang=$lang&Alti=$alti&Size=$ww,$hh&Offs=0.0,0.0&"
    verbose 1 "$URL"
    wget --header "Cookie: jscript=1;" -q -U "$UA" -O $OMAP "$URL"
    convert -geometry ${MAPWIDTH}x${MAPHEIGHT}! $OMAP $IMAP
    # I could not get curl to work with this source...
    # curl -L -s -A "$UA" -b "jscript=1;" "$URL" > $IMAP
    ;;

3|tiger)
#VERBOSE=1
    #
    # Convert the desired scale of the map to delta lat/lon for tiger
    #
    PIXELFACT=2840
    PIXELFACT=2817.947378
    meters=`echo "$MAPSCALE $h * $PIXELFACT /p" | dc`
    dlat=`calc_latlon dlat $LATcenter $LONcenter $meters 0`
    meters=`echo "$MAPSCALE $w * $PIXELFACT /p" | dc`
    dlon=`calc_latlon dlon $LATcenter $LONcenter $meters 90`

    kdlat=$dlat
    kdlon=$dlon
    #kdlat=`dc -e "$dlat 0.998 *p"`
    #kdlon=`dc -e "$dlon 0.992 *p"`

    # GRID (graticule, along with margin labelling)
    # BACK (blue background)
    # CITIES (labels on places) [actually, adds circle marks]
    # states (state boundaries, which also form white land fill over BACK)
    # counties (county boundaries)
    # places (cities and towns)
    # majroads (expressways and other highways)
    # streets (normal streets-don't turn this on when zoomed way out)
    # railroad (railroads)
    # water (water bodies, including linear streams and areal features)
    # shorelin (lines bordering areal water bodies)
    # miscell (miscellaneous features, including parks and schools)
    # interstate	[add labels for interstate highways]
    # ushwy		[add labels for US highways]
    # statehwy		[add labels for state highways]
    URL="http://tiger.census.gov/cgi-bin/mapper/map.gif"
    URL="http://tiger.census.gov/cgi-bin/mapgen/.gif"
    URL="$URL?lat=$LATcenter&lon=$LONcenter"
    URL="$URL&wid=$kdlon&ht=$kdlat&iwd=$w&iht=$h"
    URL="$URL&on=places,majroads,interstate,ushwy,statehwy,water,miscell"

    # If the map scale is small enough, add streets
    if [ "$MAPSCALE" -le 20000 ]; then
	URL="$URL,streets"
    fi

    verbose 1 "$URL"
    wget -q -U "$UA" -O $IMAP "$URL"
    ;;

4|terra*|5|topo*)
    log=`awk -v s=$MAPSCALE -v PIXELFACT=$PIXELFACT '
	    BEGIN {
		mpp = int(s/PIXELFACT + 0.5)	# desired meters per pixel
		log2 = log(mpp)/log(2)		# base2 log of mpp
		ilog2 = int(log2)
		if (log2 > ilog2) ++ilog2	# ceil(log2)
		# clamp to legal values
		if (ilog2 <= 0) ilog2 = 0
		else if (ilog2 > 9) ilog2 = 9
		print ilog2
	    }'`
    case "$MAPSRC" in
    5|topo*)
	if [ $log -lt 1 ]; then
	    log=1
	fi
    esac
	
    mpp=`echo " 2 $log ^p" | dc`
    scalecode=`echo "10 $log +p" | dc`
    MAPSCALE=`echo "$mpp $PIXELFACT *p" | dc`

    case "$MAPSRC" in
    4|terra*)	theme=1;;
    5|topo*)	theme=2;;
    esac
    URL="http://terraservice.net/GetImageArea.ashx"
    URL="$URL?t=$theme"		#theme: 1=aerial, 2=topo
    URL="$URL&s=$scalecode&lon=$LONcenter&lat=$LATcenter"
    URL="$URL&w=$w&h=$h"
    URL="$URL&f=Tahoma,Arial,Sans-serif&fs=8&fc=ffffffff&logo=1"
    verbose 1 "$URL"
    wget -q -U "$UA" -O $IMAP "$URL"
    GOTFMT=jpg
    ;;

6|gc|7|gc-icons)
    debug 0 "BROKEN: this source is temporarily/permanently out of order"
    cookies=
    case "$MAPSRC" in
    6|gc)
	    # Must login to gc.com in order to turn off icon overlays
	    gc_login "$USERNAME" "$PASSWORD"
	    cookies="-b $COOKIE_FILE"
	    icons=
	    ;;
    *)	    icons="-dchkTax2=on -dchkTax3=on -dchkTax6=on -dchkTax8=on"
	    icons="$icons -dchkTax5=on -dchkTax11=on -dchkTax4=on"
	    icons="$icons -dchkTax14=on -dchkFound=on -dchkNew=on"
	    ;;
    esac

    PAGE=${TMP}-page.html
    CRUFT="$CRUFT $PAGE"

    # This one has non-uniform and *odd* scaling levels...
      if [ $MAPSCALE -le    4000 ]; then    MAPSCALE=4000; scalecode=9;
    elif [ $MAPSCALE -le    8000 ]; then    MAPSCALE=8000; scalecode=8;
    elif [ $MAPSCALE -le   20000 ]; then   MAPSCALE=20000; scalecode=7;
    elif [ $MAPSCALE -le   40000 ]; then   MAPSCALE=40000; scalecode=6;
    elif [ $MAPSCALE -le   80000 ]; then   MAPSCALE=80000; scalecode=5;
    elif [ $MAPSCALE -le  160000 ]; then  MAPSCALE=160000; scalecode=4;
    elif [ $MAPSCALE -le  400000 ]; then  MAPSCALE=400000; scalecode=3;
    elif [ $MAPSCALE -le  800000 ]; then  MAPSCALE=800000; scalecode=2;
    elif [ $MAPSCALE -le 1600000 ]; then MAPSCALE=1600000; scalecode=1;
    elif [ $MAPSCALE -le 4000000 ]; then MAPSCALE=4000000; scalecode=0;
    else                                 MAPSCALE=4000000; scalecode=0; fi

    # First get just picks up a valid viewstate
    URL="http://www.geocaching.com/map/getmap.aspx"
    URL="$URL?lat=$LATcenter&lon=$LONcenter"
    verbose 1 "$URL"
    curl $CURL_OPTS -s -A "$UA" $cookies "$URL" > $PAGE

    gc_getviewstate $PAGE

    # Now get the page with the desired zoom
    verbose 1 "$URL (zoom $scalecode)"
    curl $CURL_OPTS -s -A "$UA" $cookies \
	-d __EVENTTARGET="" \
	-d __EVENTARGUMENT="" \
	$viewstate \
	-d"btnZoom$scalecode.x=13" \
	-d"btnZoom$scalecode.y=13" \
	    $icons \
	    -d"Navigate=rbPan" \
	"$URL" \
	> $PAGE

    # Now grab the image
    img=`grep '?map=' $PAGE | sed -n 's/.*src="\([^"]*\)".*/\1/p'`
    URL="http://www.geocaching.com/map/$img"
    URL=`echo "$URL" | sed 's/\&amp;/\&/'`
    verbose 1 "$URL"
    curl $CURL_OPTS -s -A "$UA" $cookies "$URL" > $OMAP

    # TOTAL HACK ALERT!!!!!
    # This re-scales the image to a 1:1 aspect ratio
    convert -geometry 400x500! $OMAP $IMAP

    GOTFMT=png
    ;;

8|9|multimap|multimap-aerial)
    #
    # Worldwide maps
    #
    # scales supported: 5k,10k,25k,100k,200k,500k,1m,2m,4m,10m,20m,40m
    #
    # This one has discrete scaling levels...
    URL="http://www.multimap.com/map/browse.cgi"
    MAPSCALE=`awk -v s=$MAPSCALE '
	BEGIN {
	    if (s <= 5000) print 5000
	    else if (s <= 10000) print 10000
	    else if (s <= 25000) print 25000
	    else if (s <= 100000) print 100000
	    else if (s <= 200000) print 200000
	    else if (s <= 500000) print 500000
	    else if (s <= 1000000) print 1000000
	    else if (s <= 2000000) print 2000000
	    else if (s <= 4000000) print 4000000
	    else if (s <= 10000000) print 10000000
	    else if (s <= 20000000) print 20000000
	    else if (s <= 40000000) print 40000000
	    else print 40000000
	}'`
    URL="$URL?scale=$MAPSCALE&lon=$LONcenter&lat=$LATcenter&mapsize=big"
    PAGE=${TMP}-page.html
    CRUFT="$CRUFT $PAGE"
    # Grab web page first because they convert to some coordinate
    # system I don't understand.
    verbose 1 "$URL"
    curl $CURL_OPTS -s -A "$UA" "$URL" > $PAGE
    LATcenter=$(grep 'geo.position' $PAGE | sed -e 's/;.*//' -e 's/.*"//')
    LONcenter=$(grep 'geo.position' $PAGE | sed -e 's/.*;//' -e 's/".*//')
    case "$MAPSRC" in
    9|multimap-aerial)
	URL=`grep 'href="photo.cgi' $PAGE |
	    sed -e 's@.*href="@http://www.multimap.com/map/@' -e 's/".*//' `
	verbose 1 "$URL"
	curl $CURL_OPTS -s -L -A "$UA" "$URL" > $PAGE
	((h10=h+10))
	URL=`grep 'name="multimap"' $PAGE |
	    sed -e 's/^.*src="//' -e 's/jpg".*/jpg/' \
		-e "s/W[0-9]*/W$w/" \
		-e "s/H[0-9]*/H$h10/" \
	    `
	GOTFMT=jpg
	;;
    *)
	URL=`grep 'input name="multimap"' $PAGE |
	    sed -e 's/^.*src="//' -e 's/gif".*/gif/' \
		-e 's/" alt=.*//' \
		-e "s/W[0-9]*/W$w/" \
		-e "s/H[0-9]*/H$h/" \
	    `
	;;
    esac
    verbose 1 "$URL"
    curl $CURL_OPTS -s -A "$UA" "$URL" > $OMAP
    convert -crop ${w}x$h $OMAP $IMAP
    ;;

black|white|gray)
    # No map at all, just plot the points.
    pbmmake -$MAPSRC $w $h | pnmtopng > $IMAP
    GOTFMT=png
    ;;

url)
    #
    # Produce a URL you can send to friends
    #
    # "http://mappoint.msn.com/map.aspx?C=44.9059%2c-93.49907
    # &A=35.83333&P=|44.9059%2c-93.49907|1|Cache|L1|"
    #
    # "P=|44.9471628293395,-93.4914858732373|flag_start|Start|L1||
    # 44.9428666848689,-93.4879615344107|flag_end|End|L1|"
    #
    # flag_start, flag_end, 1=redpin, 2=yelpin, 3=blupin
    #
    # Table of symbols...
    # http://msdn.microsoft.com/library/default.asp?url=/library/en-us/mpn30m/html/mpn30devTablesIcons.asp

    alti=`awk -v s=$MAPSCALE 'BEGIN { printf "%d", s/3950.0 + 0.5 }'`
    debug 1 "scale=$MAPSCALE, alti=$alti"

    URL="http://mappoint.msn.com/map.aspx"
    URL="$URL?C=$LATcenter,$LONcenter"
    URL="$URL&A=$alti"
    URL="$URL&P="
    ((i=0))
    while ((i < Npts)); do
	LAT=${Lat[i]}
	LON=${Lon[i]}
	LABEL=${Label[i]}
	SYMBOL=${Symbol[i]}

	LABEL=`urlencode2 "$LABEL"`
	# Attempt to map our (tigers) set of symbols into theirs...
	case "$SYMBOL" in
	[sS][0-9]*) SYMBOL=`echo "$SYMBOL" | sed 's/^.//'` ;;
	reddot*)	SYMBOL=9;;
	orgdot*)	SYMBOL=8;;
	grndot*)	SYMBOL=23;;
	purdot*)	SYMBOL=10;;
	magdot*)	SYMBOL=10;;
	???dot*)	SYMBOL=11;;
	redpin*)	SYMBOL=5;;
	blupin*)	SYMBOL=4;;
	purpin*)	SYMBOL=6;;
	???pin)		SYMBOL=7;;
	*)		SYMBOL=21;;
	esac
	((++i))
	if [ $LBLCOORDS = 1 ]; then
	    LABEL="$LABEL, `degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
	fi
	URL="$URL|$LAT,$LON|$SYMBOL|$LABEL|L1|"
    done 
    echo "$URL"
    exit
    ;;

*.gif)
    # Existing map file
    cp "$MAPSRC" $IMAP || error "Cannot open existing map file '$MAPSRC'"
    w=`gifinfo -f "\w" "$MAPSRC"`
    h=`gifinfo -f "\h" "$MAPSRC"`
    ;;
*.png)
    # Existing map file
    file "$MAPSRC" | cut -d',' -f2 > $IMAP
    read w x h x < $IMAP
    cp "$MAPSRC" $IMAP || error "Cannot open existing map file '$MAPSRC'"
    ;;

#
#	Half-complete attempts...
#
etree)
    #incomplete
    URL="http://sauron.etree.com/Scripts/usgsmapsJ.dll"
    URL="$URL?map=1,1,50,1,$LATcenter,$LONcenter"
    URL="$URL,$LATcenter,$LONcenter,255,0,0,7,*"
    h=600; w=600;
    verbose 1 "$URL"
    curl $CURL_OPTS -s -A "$UA" "$URL" > $IMAP
    ;;

10|mappoint)
    debug 0 "TODO: this source not yet implemented"
    # TODO: adjust scale based on legal altitudes
    alti=50
    w=800
    h=740
    # TODO snag session #
    session=
    URL="http://mappoint.msn.com/($session)/MPSvc.aspx"
    URL="$URL?MPMtd=M&ID=27CiJ.&L=USA"
    URL="$URL&C=$LATcenter,$LONcenter&A=$alti&S=$w,$h"
    verbose 1 "$URL"
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $IMAP
    ;;

11|maporama)
    # Very nice international map source, dunno if it supports lat/lon
    debug 0 "TODO: this source not yet implemented"
    # http://www.maporama.com/image.asp?XgoPageName=XMLOUT&XgoUserID=8A5D25B61F1749C8&XgoNbReq=13&XgoAnswer=Gif&sizex=1280&sizey=1024&CODE=praire
    exit
    ;;

12|natgeo|ng)
VERBOSE=1
    debug 0 "Minimum scale is -s650"
    debug 0 "TODO: this source not yet scaled properly"

    #
    # Convert the desired scale of the map to delta lat/lon for tiger
    #
    meters=`echo "$MAPSCALE $h * $PIXELFACT /p" | dc`
    dlat=`calc_latlon dlat $LATcenter $LONcenter $meters 0`
    meters=`echo "$MAPSCALE $w * $PIXELFACT /p" | dc`
    dlon=`calc_latlon dlon $LATcenter $LONcenter $meters 90`

    debug 1 "Delta: $dlat $dlon"
    LATll=$(awk "BEGIN { print $LATcenter - $dlat/2.0 }")
    LATur=$(awk "BEGIN { print $LATcenter + $dlat/2.0 }")
    LONll=$(awk "BEGIN { print $LONcenter - $dlon/2.0 }")
    LONur=$(awk "BEGIN { print $LONcenter + $dlon/2.0 }")
    debug 1 "corners: LATll $LONll      $LATur $LONur"

    PAGE=${TMP}-page.html
    CRUFT="$CRUFT $PAGE"

    URL="http://mapmachine.nationalgeographic.com/mapmachine"
    URL="$URL/viewandcustomizepage.html?task=getMap&themeId=110"
    URL="$URL&ext=$LONll,$LATll,$LONur,$LATur&size=l"

    verbose 1 "$URL"
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $PAGE

    URL=$(grep '"mapImage"' $PAGE | sed -e 's/.*src="//' -e 's/".*//')
    echo "$URL"
    if [ "$URL" = "" ]; then
	error "Unable to extract map URL"
    fi
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $IMAP
    ;;

13|ts*|citipix|globex*)
    # terraserver.COM.  The TOS says...
    # " Any derivative products you make from the image, such as maps or
    #   composite illustrations, etc., are your own property."
    RES=8	# meters/pixel
    #PROV=103	# provider: geocomm (1m USGS)
    #PROV=200	# provider: USGS (1m)
    #PROV=210	# provider: USGS Urban (1m)
    PROV=305	# provider: AirPhoto USA
    PROV=320	# provider: DigitalGlobe (2ft/.6096m satellite)
    PROV=350	# provider: GlobeXplorer (intl, mixed res)
    PROV=300	# provider: Citipix (6in/.1524m  resolution available)

    BASEURL="http://www.terraserver.com/imagery/image_gx.asp"
    BASEURL="$BASEURL?cpx=$LONcenter&cpy=$LATcenter"
    URL="$BASEURL&res=$RES"

    mapsrc=$(echo "$MAPSRC" | tr '[A-Z]' '[a-z]')
    case "$mapsrc" in
    *103)		PROV=103;;
    *200)	PROV=200
		RES=10
		BASEURL="http://www.terraserver.com/imagery/image_usgs.asp"
		BASEURL="$BASEURL?cpx=$LONcenter&cpy=$LATcenter"
		URL="$BASEURL&usgs_res=$RES"
		;;
    *210)		PROV=210;;
    *300|*citipix)				PROV=300;;
    *305|*airphoto)				PROV=305;;
    ts2|*310)		PROV=310;;
    *320|*digitalglobe)				PROV=320;;
    *322)		PROV=322;;	# UK
    *350|*globex*)	PROV=350;;
    *512|*landvoyage)
		PROV=512
		;;
    *600|*601|*getmapping|*getmappingultra)
		COORDS=${TMP}-coords.txt
		CRUFT="$CRUFT $COORDS"
		ll2osg $LATcenter $LONcenter > $COORDS
		if [ $? != 0 ]; then
		    error "error in ll2osg"
		fi
		read cpx cpy other < $COORDS
		BASEURL="http://www.terraserver.com/imagery/image_gm.asp"
		BASEURL="$BASEURL?cpx=$cpx&cpy=$cpy"
		URL="$BASEURL&res=$RES"
		case "$mapsrc" in
		*600|*getmapping) PROV=600;;
		*601|*getmappingultra) PROV=601;;
		esac
		;;	# UK
    *)		PROV=300;;
    esac

    URL="$URL&provider_id=$PROV"

    PAGE=${TMP}-page.html
    CRUFT="$CRUFT $PAGE"
    COOKIES=$HOME/.tscom.cookies

    if [ "$TSCOM_EMAIL" != "" ]; then
	# If a subscriber, then login.  But only if we don't have fresh cookies
	if [ ! -f $COOKIES ]; then
	    $touch -d "1/1/70" $COOKIES
	fi
	TIMESTAMP=${TMP}-timestamp; CRUFT="$CRUFT $TIMESTAMP"
	$touch -d "1 minutes ago" $TIMESTAMP
	if [ $COOKIES -ot $TIMESTAMP ]; then
	    LURL=http://www.terraserver.com/account/login.asp
	    verbose 1 "$LURL"
	    curl $CURL_OPTS -L -a -A "$UA" \
		-c "$COOKIES" \
		-d "login_attempt=true" \
		-d "email=$TSCOM_EMAIL" \
		-d "password=$TSCOM_PW" \
		$LURL > /dev/null 2>&1
	else
	    touch $COOKIES
	fi
    fi

    # Fetch page the first time to see what scales are available to us
    verbose 1 "$URL"
    curl $CURL_OPTS -L -s -A "$UA" -b "$COOKIES" "$URL" > $PAGE

    # Globe Explorer
    # <option value="0.1524">0.1524m  (6 in.)</option>
    # <option value="0.25">0.25m</option><option value="0.3048">0.3048m (1 ft.)</option><option value="0.5">0.5m</option><option value="0.6096">0.6096m (2 ft.)</option>
    # <option value="1">1 m</option>
    # <option value="2">2 m</option>
    # <option value="3">3 m</option>
    # <option value="4">4 m</option>
    # <option value="128">128 m</option>

    # USGS
    # <option value="10">1 m</option>
    # <option value="11">2 m</option>
    # <option value="12">4 m</option>
    # <option value="13">8 m</option>
    # <option value="14">16 m</option>
    # <option value="15">32 m</option>
    # <option value="16">64 m</option>
    # <option value="17">128 m</option>

    # Figure out the best scale (in meters/pixel)  available to us
    RES=$(split_lines_between "</option>" "<option" g < $PAGE |
	    awk -v s=$MAPSCALE -v PIXELFACT=$PIXELFACT '
	    BEGIN {
		mpp = s/PIXELFACT	# desired meters per pixel
		# printf "desired mpp = %f\n", mpp
	    }
	    /option value=.*m.*<.option>/ {
		avail = $0
		sub(/[^"]*"/, "", avail)
		sub(/".*/, "", avail)
		if (mpp <= avail) {
		    exit
		}
	    }
	    /Quick Pan/ { exit }
	    END {
		print avail
	    }'
	)
    if [ "$RES" = "" ]; then
	error "No maps available from that source at the desired resolution"
    fi

    # Recompute the new mag scale
    MAPSCALE=$(awk "BEGIN { print $RES * $PIXELFACT }")

    # Figure out the date the picture was taken
    DT=$(awk < $PAGE '
	    /<td>Date:<.td>/ { doit = 1; next }
	    doit == 1 { sub("[ 	]*", ""); sub("<td>", ""); sub("<.td>", "");
		print; exit }
	    ')
    verbose 1 "Date taken: $DT"
    if [ "" = "$FOOTER" ]; then
	    FOOTER="Date taken: $DT"
    fi
    if [ " " = "$FOOTER" ]; then
	    FOOTER=""
    fi

    # Fetch the page at the desired scale.
    case "$MAPSRC" in
    *200)	URL="$BASEURL&usgs_res=$RES&provider_id=$PROV"
		;;
    *)		URL="$BASEURL&res=$RES&provider_id=$PROV";;
    esac
    verbose 1 "$URL"
    curl $CURL_OPTS -L -s -A "$UA" -b "$COOKIES" -c "$COOKIES" "$URL" > $PAGE

    # Other interesting info on the page...
    # var js_ulx = -93.52567894906;
    # var js_uly = 45.01799533362;
    # var js_lrx = -93.47432124503;
    # var js_lry = 44.98200452523;
    # var js_cpx = -93.5;
    # var js_cpy = 45;
    # var js_resolution = 8;
    # var js_provider_id = 300;
    # var js_min_resolution = 0.1524;
    # var js_res_ratio = 52.49343832021;
    #
    #    <select name="zoom" onchange="Javascript:quick_zoom(this.value)">
    #            <option value="0"></option>
    #            <option value="8">8 m</option>
    #            <option value="10">10 m</option>
    #            <option value="120">120 m</option>
    #            <option value="128">128 m</option>
    #    </select>
    #

    # The image URL is in the cookie GXURL (7th field)
    get_cookie() {
	while read site flag slash flag num name value extra; do
	    if [ $2 = "$name" ]; then
		break
	    fi
	done < $1
	echo $value | sed \
	    -e 's/%3A/:/g' \
	    -e 's/%2F/\//g' \
	    -e 's/%2E/./g' \
	    -e 's/%3D/=/g' \
	    -e 's/%3F/?/g' \
	    -e 's/%26/\&/g' \

    }
    case "$PROV" in
    600|601)	URL=`get_cookie $COOKIES GMURL`;;
    *)		URL=`get_cookie $COOKIES GXURL`;;
    esac
    if [ "$URL" = "" ]; then
	error "Unable to extract map URL"
    else
	verbose 1 "$URL"
    fi
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $IMAP
    ;;

tmrs)
    # Tiger mapping server -- local map generation
    # http://sumitbirla.com/software/tmrs.php
    # ./tmrs -d ../mn -m "PNG,640,480,10,44947763,-93493132" > xxx
    debug 0 "TODO: this source not yet scaled properly"
    GOTFMT=png
    DATADIR=$HOME/lib/tmrs/ESRI
    ilat=$(awk -v "v=$LAT" 'BEGIN { printf("%d\n", v*1000000) }')
    ilon=$(awk -v "v=$LON" 'BEGIN { printf("%d\n", v*1000000) }')
    iscale=$(awk -v "v=$MAPSCALE" 'BEGIN { printf("%d\n", v/1000) }')
    CMD="tmrs -d $DATADIR -m PNG,$w,$h,$iscale,$ilat,$ilon"
    $CMD > $IMAP
    ;;

30|aolterra)
    #zoom 	scale
    #	1 	88011773
    #	2 	29337258
    #	3 	9779086
    #	4 	3520471
    #	5 	1504475
    #	6 	701289
    #	7 	324767
    #	8 	154950
    #	9 	74999
    #	10 	36000
    #	11 	18000
    #	12 	9000
    #	13 	4700
    #	14 	2500
    #	15 	1500
    #	16 	1000
    MAPSCALE=`awk -v s=$MAPSCALE '
	BEGIN {
	    if (s <= 1000) print 1000
	    else if (s <= 1500) print 1500
	    else if (s <= 2500) print 2500
	    else if (s <= 4700) print 4700
	    else if (s <= 9000) print 9000
	    else if (s <= 18000) print 18000
	    else if (s <= 36000) print 36000
	    else if (s <= 74999) print 74999
	    else if (s <= 154950) print 154950
	    else if (s <= 324767) print 324767
	    else if (s <= 701289) print 701289
	    else if (s <= 1504475) print 1504475
	    else if (s <= 3520471) print 3520471
	    else if (s <= 9779086) print 9779086
	    else if (s <= 29337258) print 29337258
	    else print 88011773
	}'`

    URL="http://mqprint-vd03.evip.aol.com/staticmap/v3/getmap"
    URL="$URL?key=YOUR_KEY_HERE"
    URL="$URL&center=$LATcenter,$LONcenter"
    #URL="$URL&zoom=$alti&size=$w,$h"
    URL="$URL&scale=$MAPSCALE&size=$w,$h"
    # type=map,hyb,sat
    URL="$URL&type=hyb&imagetype=png"
    # &pois=mcenter,40.044600,-76.413100"
    GOTFMT=png
    debug 0 "curl '$URL' > xxx"
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $IMAP
    ;;

ge)
    w=450
    h=350
    debug 0 "TODO: this source not yet scaled properly"
    echo "$LATmax $LONmax"
    GOTFMT=jpg

    meters=`echo "$MAPSCALE $h * $PIXELFACT /p" | dc`
    dlat=`calc_latlon dlat $LATcenter $LONcenter $meters 0`
    meters=`echo "$MAPSCALE $w * $PIXELFACT /p" | dc`
    dlon=`calc_latlon dlon $LATcenter $LONcenter $meters 90`
    ULlat=` echo "scale=6; $LATcenter + ($dlat/2)" | bc`
    ULlon=` echo "scale=6; $LONcenter - ($dlon/2)" | bc`
    LRlat=` echo "scale=6; $LATcenter - ($dlat/2)" | bc`
    LRlon=` echo "scale=6; $LONcenter + ($dlon/2)" | bc`

    URL="http://image.globexplorer.com/gexservlets/gex?cmd=image"
    URL="$URL&id=3910000291&appid=020100S"
    URL="$URL&ls=19&iw=$w&ih=$h"
    #URL="$URL&xul=440000"
    URL="$URL&xul=`ll2utm -e -- $ULlat $ULlon`"
    #URL="$URL&yul=4980896"
    URL="$URL&yul=`ll2utm -n -- $ULlat $ULlon`"
    #URL="$URL&xlr=441284"
    URL="$URL&xlr=`ll2utm -e -- $LRlat $LRlon`"
    #URL="$URL&ylr=4980546"
    URL="$URL&ylr=`ll2utm -n -- $LRlat $LRlon`"
    URL="$URL&projid=32615&tid=8471221226,8471221227" 
    debug 0 "curl '$URL' > xxx"
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $IMAP
    ;;

20|osm|osmmapnik|osmapnik)
    # Mapnik needs lower-left and upper-right corners
    meters=`echo "$MAPSCALE $h * $PIXELFACT /p" | dc`
    dlat=`calc_latlon dlat $LATcenter $LONcenter $meters 0`
    meters=`echo "$MAPSCALE $w * $PIXELFACT /p" | dc`
    dlon=`calc_latlon dlon $LATcenter $LONcenter $meters 90`
    LLlat=` echo "scale=6; $LATcenter - ($dlat/2)" | bc`
    LLlon=` echo "scale=6; $LONcenter - ($dlon/2)" | bc`
    URlat=` echo "scale=6; $LATcenter + ($dlat/2)" | bc`
    URlon=` echo "scale=6; $LONcenter + ($dlon/2)" | bc`
    # information gathered empirically:
    # OSM Mapnik has a "floating" scale
    # to match former Expedia output, we have to use a "fudge factor" of
    # 2.0775 at ~52.4°, ~1.79 at 45°, ~1.276 at 0° (equator)
    # basically ff(phi)=ff(0)/cos(phi)
    # but we have to correct for the ellipsoid, too!
    # with GRS80,
    # equatorial radius   a=6378.137km 
    # flattening        1/f=298.257222101
    # giving polar radius b=6356.752km
    # latitude-dependent radius (taken from WP:Earth_radius)
    # r(phi)=sqrt((a^4*cos^2(phi)+b^4*sin^2(phi))
    #			/(a^2*cos^2(phi)+b^2*sin^2(phi)))
    # this should give a "fudge factor" of ff=constant*(r(phi)/a)/cos(phi)
    # with constant~1.276 (to be adjusted)
    a=6378137.0
    f1=298.257222101
    pi=3.141592653
    # FIXME!
    # this has to be adjusted so images sizes are preserved for all latitudes
    # 1.2757 works for lats up to >52° but slightly diverges towards the pole
    fudge=1.2757
    # start the real calculation
    cosphi=`awk -vphi=$LATcenter -vpi=$pi 'BEGIN{
	printf("%.7f",cos(phi/180.0*pi))}'`
    radius=`awk -vphi=$LATcenter -vpi=$pi -va=$a -vf1=$f1 'BEGIN{
	cosphi=cos(phi/180.0*pi)
	sinphi=sin(phi/180.0*pi)
	b=a*(1.0-1.0/f1)
	radius=sqrt((a*a*a*a*cosphi*cosphi+b*b*b*b*sinphi*sinphi)/ \
		    (a*a    *cosphi*cosphi+b*b    *sinphi*sinphi))
	printf("%.1f",radius)
	}'`
    # I have no idea why r/a has to be taken to the 3rd power, but it works :-/
    scale=` echo "scale=2; \
	$MAPSCALE \
	/ $cosphi \
	* $fudge \
	* $radius / $a \
	* $radius / $a \
	* $radius / $a \
	" | bc`
    ww=$w
    hh=$h
    while [ $ww -gt 2000 -o $hh -gt 2000 ]; do
	scale=`echo "scale=2; $scale * 2" | bc`
	ww=$(($ww / 2))
	hh=$(($hh / 2))
    done
    debug 1 "cosphi=$cosphi radius=$radius scale=$scale w=$ww h=$hh"
    URL="http://tile.openstreetmap.org/cgi-bin/export?format=png"
    URL="$URL&bbox=$LLlon,$LLlat,$URlon,$URlat"
    URL="$URL&scale=$scale"
    debug 1 "curl '$URL'"
    #
    # Try for 52.5 minutes
    #
    count=0
    while ((count < 20))
    do
	((count=count+1))
	curl $CURL_OPTS -L -s -A "$UA" "$URL" > $OMAP
	case `file $OMAP` in
        *HTML*)	if [ "$DEBUG" -gt 0 ]; then printf "."; fi
		((s=count*15))
		sleep $s
		;;
        *)	if [ "$DEBUG" -gt 0 ]; then echo ""; fi
		break
		;;
	esac
    done
    convert -geometry ${MAPWIDTH}x${MAPHEIGHT}! $OMAP $IMAP
    GOTFMT=png
    ;;

21|osmstatic)
    # Use static maps for now, but is broken with scale

    # uses fixed zoom levels (as in gc)
    # numbers in OSM wiki for "meters per pixel" at equator
    # http://wiki.openstreetmap.org/wiki/FAQ#Questions_from_GIS_people
    # at 72 dpi, 1 px is 1/72 in = .00035277 m:
    #	zoom  2		39135.76  m/px	1:110,936,000
    #	zoom  4		 9783.94  m/px	1: 27,734,000
    #	zoom  7		 1222.99  m/px	1:  3,466,743
    #	zoom 10		  152.874 m/px	1:    433,344
    #	zoom 13		   19.109 m/px	1:     54,167
    #	zoom 14		    9.555 m/px	1:     27,084
    #	zoom 16		    2.389 m/px	1:      6,771
    #	zoom 17		    1.194 m/px	1:      3,385
    #	zoom 18		    0.597 m/px	1:      1,693 - does this exist?

    # 1° equals 11650 pixels at zoom level 14, 
    # - in both NS and EW directions at the equator
    # - in EW everywhere else
    # - at latitude phi, 1° NS equals 11650/cos(phi) pixels.
    #
    # Since Osmarender uses _spherical_ Mercator, some deviations will happen.
    #
    # 1° EW at latitude phi = R*(pi/180)*cos(phi)
    # 1° NS at latitude phi = R*(pi/180)           with R=6378.137km
    #
    # zoom 17: 93200 pixels/° -> 837 pixels/km -> 1:3343
    # (cf. Expedia 1:19750 -> 15777 pixels/°)
    # at equator; at latitude phi: 1:3343*cos(phi)
    # scales in Wiki *seem* to be off by ~1%? 

    pi=3.141592653
    cosphi=`awk -vphi=$LATcenter -vpi=$pi 'BEGIN{
	printf("%.7f", cos(phi/180.0*pi))}'`
    radius=6378137.0
    #    zoomscale=1675.7 #1692.75
    #    zoomlevel=18
    zoomscale=3351.5 #3385.5
    zoomlevel=17
    # find largest z <= (corrected) scale; we have to shrink the image!
    line=`echo $MAPSCALE $cosphi $zoomscale $zoomlevel \
    | awk '{
	    s=$1; y=$3*$2; z=$4;
	    while (z>=0){
		if((z==0)||(s<y*2)){printf("%d:%.1f",z,y); exit;}
		z-=1; y*=2;
	    }
	}'`
    z=${line%%:*}
    scale=${line##*:}
    debug 1 "zoom $z eff.scale $scale"
    # get image size
    ww=`echo $MAPSCALE $scale $MAPWIDTH  | awk '{printf("%.0f",$1/$2*$3)}'`
    hh=`echo $MAPSCALE $scale $MAPHEIGHT | awk '{printf("%.0f",$1/$2*$3)}'`
    #ww=$MAPWIDTH
    #hh=$MAPHEIGHT
    # map server refuses maps larger than 2000 pixels
    while [ $ww -gt 2000 -o $hh -gt 2000 ]; do
	scale=`echo "$scale * 2" | bc`
	z=`echo "$z - 1" | bc`
	ww=`echo $MAPSCALE $scale $MAPWIDTH  | awk '{printf("%.0f",$1/$2*$3)}'`
	hh=`echo $MAPSCALE $scale $MAPHEIGHT | awk '{printf("%.0f",$1/$2*$3)}'`
    done
    debug 1 "new zoom=$z scale=$scale width=$ww height=$hh"
    URL="http://tah.openstreetmap.org/MapOf/index.php?skip_attr=on&format=png"
    URL="http://ojw.dev.openstreetmap.org/StaticMap/?att=none&layer=cloudmade_2&mode=Export&show=1"
    #URL="$URL&lat=$LATcenter&long=$LONcenter"
    URL="$URL&lat=$LATcenter&lon=$LONcenter"
    URL="$URL&z=$z"
    URL="$URL&w=$ww&h=$hh"
    debug 1 "curl '$URL'"
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $OMAP
    convert -geometry ${MAPWIDTH}x${MAPHEIGHT}! $OMAP $IMAP
    GOTFMT=png
    ;;

41|gstatic|42|gstatic-hybrid|43|gstatic-terrain|44|gstatic-aerial)
    # https://developers.google.com/maps/documentation/static-maps/

    pi=3.141592653
    cosphi=`awk -vphi=$LATcenter -vpi=$pi 'BEGIN{
	printf("%.7f", cos(phi/180.0*pi))}'`
    radius=6378137.0
    zoomscale=1675.7 #1692.75
    zoomlevel=18
    # find largest z <= (corrected) scale; we have to shrink the image!
    line=`echo $MAPSCALE $cosphi $zoomscale $zoomlevel \
    | awk '{
	    s=$1; y=$3*$2; z=$4;
	    while (z>=0){
		if((z==0)||(s<y*2)){printf("%d:%.1f",z,y); exit;}
		z-=1; y*=2;
	    }
	}'`
    z=${line%%:*}
    scale=${line##*:}
    debug 1 "zoom $z eff.scale $scale"
    # get image size
    ww=`echo $MAPSCALE $scale $MAPWIDTH  | awk '{printf("%.0f",$1/$2*$3)}'`
    hh=`echo $MAPSCALE $scale $MAPHEIGHT | awk '{printf("%.0f",$1/$2*$3)}'`
    # map server refuses/distorts maps larger than 640 pixels
    while [ $ww -gt 640 -o $hh -gt 640 ]; do
	scale=`echo "$scale * 2" | bc`
	z=`echo "$z - 1" | bc`
	ww=`echo $MAPSCALE $scale $MAPWIDTH  | awk '{printf("%.0f",$1/$2*$3)}'`
	hh=`echo $MAPSCALE $scale $MAPHEIGHT | awk '{printf("%.0f",$1/$2*$3)}'`
    done
    debug 1 "new zoom=$z scale=$scale width=$ww height=$hh"
    URL="https://maps.googleapis.com/maps/api/staticmap?"
    URL="$URL&key=$GMAP_KEY"
    URL="$URL&center=$LATcenter,$LONcenter"
    URL="$URL&zoom=$z"
    URL="$URL&size=${ww}x${hh}"
    case "$MAPSRC" in
    42|gstatic-hybrid)	URL="$URL&maptype=hybrid";;
    43|gstatic-terrain)	URL="$URL&maptype=terrain";;
    44|gstatic-aerial)	URL="$URL&maptype=satellite";;
    esac
    debug 1 "curl '$URL'"
    curl $CURL_OPTS -L -s -A "$UA" "$URL" > $OMAP
    if grep -q "Google Maps Platform server rejected your request" $OMAP; then
	error "`cat $OMAP`"
    fi
    # scale (up) to requested size
    convert -geometry ${MAPWIDTH}x${MAPHEIGHT}! $OMAP $IMAP
    GOTFMT=png
    ;;

9[0-9]|tms-*)
    # define tile server and image type
    TYPE=""
    BASEURL=""
    MAXZOOM=18 # most common limit
    MINZOOM=4  # could be 0 but makes little sense
    TILESIZE=256
    case $MAPSRC in
    91|tms-osm)
	MAXZOOM=19
	TYPE=png; BASEURL=http://tile.openstreetmap.org;;
    92|tms-osmcycle|tms-ocm)
	TYPE=png; BASEURL=http://tile.opencyclemap.org/cycle;;
       tms-transport|tms-trans)
	TYPE=png; BASEURL=http://tile2.opencyclemap.org/transport;;
       tms-openptmap|tms-pt)
	TYPE=png; BASEURL=http://www.openptmap.org/tiles;;
       tms-openrailwaymap|tms-rail)
	TILESIZE=512
	TYPE=png; BASEURL=http://tiles.openrailwaymap.org/standard;;
    93|tms-osmde)
	TYPE=png; BASEURL=http://tile.openstreetmap.de/tiles/osmde;;
       tms-humanitarian|tms-hot)
	TYPE=png; BASEURL=http://a.tile.openstreetmap.fr/hot;;
    94|tms-mapquest|tms-mq) # otile[1-4]
	TYPE=jpg; BASEURL=http://otile2.mqcdn.com/tiles/1.0.0/osm;;
       tms-openaerial|tms-mqoa)
	TYPE=jpg; BASEURL=http://otile2.mqcdn.com/tiles/1.0.0/sat;;
    95|tms-maptoolkit|tms-mtk) # tile[0-9]
	TYPE=png; BASEURL=http://tile2.maptoolkit.net/terrain;;
    96|tms-gpsies)
	TYPE=png; BASEURL=http://hikebike.gpsies.com;;
#      tms-hikebike) IDENTICAL
#	TYPE=png; BASEURL=http://tiles.wmflabs.org/hikebike;;
       tms-thunderforest|tms-outdoors)
	TYPE=png; BASEURL=http://tile.thunderforest.com/outdoors;;
#      tms-openpiste) #DISABLED Nov 2015
#	TYPE=png; BASEURL=http://tiles.openpistemap.org/nocontours;;
    97|tms-terrain)
	TYPE=png; BASEURL=http://tile.stamen.com/terrain;;
    98|tms-toner)
	TYPE=png; BASEURL=http://tile.stamen.com/toner;;
    99|tms-watercolor)
	TYPE=jpg; BASEURL=http://tile.stamen.com/watercolor;;
    tms-gif-*|tms-jpg-*|tms-png-*)
	TYPE=`echo $MAPSRC | cut -d- -f2`
	BASEURL=http://`echo $MAPSRC | cut -d- -f3-`;;
    *)
	echo "Unknown map source $MAPSRC"
	;;
    esac
    if [ -n "$TYPE" ]; then
	# corner coordinates (code copied from above)
	meters=`echo "$MAPSCALE $h * $PIXELFACT /p" | dc`
	dlat=`calc_latlon dlat $LATcenter $LONcenter $meters 0`
	meters=`echo "$MAPSCALE $w * $PIXELFACT /p" | dc`
	dlon=`calc_latlon dlon $LATcenter $LONcenter $meters 90`
	LLlat=` echo "scale=6; $LATcenter - ($dlat/2)" | bc`
	LLlon=` echo "scale=6; $LONcenter - ($dlon/2)" | bc`
	URlat=` echo "scale=6; $LATcenter + ($dlat/2)" | bc`
	URlon=` echo "scale=6; $LONcenter + ($dlon/2)" | bc`
	debug 1 "scale=$MAPSCALE w=$w h=$h"
	debug 2 "LL $LLlat,$LLlon UR $URlat,$URlon"
	debug 1 "TL $URlat,$LLlon BR $LLlat,$URlon"
	# make sure nothing gets in our way
	rm -rf $IMAP
	mkdir -p $IMAP
	# we cannot
	#    trap "rm -rf $IMAP" 0 1 2 3 6 9 15
	# ! modify remove_cruft "rm -f" becomes "rm -rf" !
	# get matching zoom scale
	z=$(($MAXZOOM+1))
	usethis=0
	until [ $usethis -eq 1 ]
	do
	    z=$(($z-1))
	    # convert lat/lon into tile coordinates
	    debug 3 "LL $LLlat $LLlon -\> `ll_xy $LLlat $LLlon $z`"
	    debug 3 "UR $URlat $URlon -\> `ll_xy $URlat $URlon $z`"
	    # 1: upper left (NW), 2: lower right (SE)
	    x1=`ll_xy $LLlat $LLlon $z | cut -d' ' -f1`
	    ix1=`echo $x1 | cut -d. -f1`
	    y1=`ll_xy $URlat $URlon $z | cut -d' ' -f2`
	    iy1=`echo $y1 | cut -d. -f1`
	    x2=`ll_xy $URlat $URlon $z | cut -d' ' -f1`
	    ix2=`echo $x2 | cut -d. -f1`
	    y2=`ll_xy $LLlat $LLlon $z | cut -d' ' -f2`
	    iy2=`echo $y2 | cut -d. -f1`
	    # tile count
	    nx=$(($ix2-$ix1+1))
	    ny=$(($iy2-$iy1+1))
	    # cropping: size and offset
	    sx=`echo $x1 $x2  | awk -vTS=$TILESIZE '{printf("%.0f", ($2-$1)*TS)}'`
	    sy=`echo $y1 $y2  | awk -vTS=$TILESIZE '{printf("%.0f", ($2-$1)*TS)}'`
	    ox=`echo $ix1 $x1 | awk -vTS=$TILESIZE '{printf("%.0f", ($2-$1)*TS)}'`
	    oy=`echo $iy1 $y1 | awk -vTS=$TILESIZE '{printf("%.0f", ($2-$1)*TS)}'`
	    debug 2 "UL $ix1 $iy1 .. LR $(($ix2+1)) $(($iy2+1))"
	    debug 2 "LL $ix1 $iy2 .. UR $(($ix2+1)) $(($iy1+1))"
	    debug 1 "${nx} x ${ny} tiles @zoom $z, geometry ${sx}x${sy}+${ox}+${oy}"
	    if [ $sx -le $MAPWIDTH -o $sy -le $MAPHEIGHT -o $z -le $MINZOOM ]; then
		usethis=1
	    fi
	done
	debug 1 "download $TYPE files from $BASEURL"
	for x in `seq $ix1 $ix2` ; do
	    for y in `seq $iy1 $iy2` ; do
		debug 2 "get $z/$x/$y.$TYPE to $IMAP/"
		wget -q -nvp -O $IMAP/$z-`printf %06d-%06d $y $x`.$TYPE $BASEURL/$z/$x/$y.$TYPE
		if [ $? -ne 0 ] ; then
		    # error handling??? use dummy tile
		    pbmmake -gray $TILESIZE $TILESIZE | pnmtopng > $IMAP/$z-`printf %06d-%06d $y $x`.png
		    debug 1 "$z/$x/$y failed"
		fi
	    done
	done
	# do not combine montage and convert - tends to hog CPU
	debug 1 "concat files to bigmap"
	montage 2> /dev/null \
	    -mode concatenate \
	    -tile ${nx}x${ny} \
		$IMAP/$z-*-*.* $IMAP/bigmap.$TYPE
	debug 1 "crop and resize bigmap to $OMAP"
	convert \
	    -crop ${sx}x${sy}+${ox}+${oy}! \
	    -geometry ${MAPWIDTH}x${MAPHEIGHT}! \
	    +repage \
		$IMAP/bigmap.$TYPE $OMAP
	# subsequent code wants a file
	rm -rf $IMAP
	cp -p $OMAP $IMAP
	GOTFMT=$TYPE
    fi
    ;;

40|gmap|gbike)
    if [ "$OFILE" = "" ]; then
	# web only, RER 06/23/16
	DOWWW=1
	OFILE=xxx.html
	# local file
	DOWWW=0
	OFILE=/tmp/xxx.html;  #DOWWW=1
    fi
    echo $MAPSCALE
    ZOOM=16
    if [ "$MAPSCALE" -lt 65536000 ]; then ZOOM=2; fi
    if [ "$MAPSCALE" -lt 32768000 ]; then ZOOM=3; fi
    if [ "$MAPSCALE" -lt 16384000 ]; then ZOOM=4; fi
    if [ "$MAPSCALE" -lt 8192000 ]; then ZOOM=5; fi
    if [ "$MAPSCALE" -lt 4096000 ]; then ZOOM=6; fi
    if [ "$MAPSCALE" -lt 2048000 ]; then ZOOM=7; fi
    if [ "$MAPSCALE" -lt 1024000 ]; then ZOOM=8; fi
    if [ "$MAPSCALE" -lt 512000 ]; then ZOOM=9; fi
    if [ "$MAPSCALE" -lt 256000 ]; then ZOOM=10; fi
    if [ "$MAPSCALE" -lt 128000 ]; then ZOOM=11; fi
    if [ "$MAPSCALE" -lt 64000 ]; then ZOOM=12; fi
    if [ "$MAPSCALE" -lt 32000 ]; then ZOOM=13; fi
    if [ "$MAPSCALE" -lt 16000 ]; then ZOOM=14; fi
    if [ "$MAPSCALE" -lt 8000 ]; then ZOOM=15; fi
    if [ "$MAPSCALE" -lt 4000 ]; then ZOOM=16; fi
    if [ "$MAPSCALE" -lt 2000 ]; then ZOOM=17; fi
    if [ "$MAPSCALE" -lt 1000 ]; then ZOOM=18; fi
    if [ "$MAPSCALE" -lt 500 ]; then ZOOM=19; fi
    cat <<-EOF > $OFILE
	<!DOCTYPE html>
	<html>
	<!-- $0 $ARGS -->
	<head> 
	  <meta http-equiv="content-type" content="text/html; charset=UTF-8" /> 
	  <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
	  <title>geo-map ...</title> 
	    <style type="text/css">
	      html { height: 100% }
	      body { height: 100%; margin: 0px; padding: 0px }
	      #map_canvas { height: 100% }
	      div#xxx { position: relative; }
	      div#latlng {
	        position: absolute;
	        bottom: 0;
	        left: 33%;
	        opacity: 0.8;
	        background-color: #ffffff;
	      }
	      div#crosshair {
	        position: absolute;
	        top: 50%;
	        margin-top: -10px;
	        height: 19px;
	        width: 19px;
	        left: 50%;
	        margin-left: -8px;
	        display: block;
	        background: url(data:image/gif;base64,R0lGODlhEwATAKEBAAAAAP///////////yH5BAEKAAIALAAAAAATABMAAAIwlI+pGhALRXuRuWopPnOj7hngEpRm6ZymAbTuC7eiitJlNHr5tmN99cNdQpIhsVIAADs=);
	        background-position: center center;
	        background-repeat: no-repeat;
	      }
	    </style>
	  <script
	    src="http://maps.google.com/maps/api/js?libraries=geometry&key=$GMAP_KEY" 
	    type="text/javascript">
	  </script>

	  <script type="text/javascript">
#include "StyledMarker.js"
          </script>
	</head>
	<body>
	<div id="xxx" style="width: 100%; height: 100%">
	    <div id="map" style="width: 100%; height: 100%;"></div>
	    <div id="crosshair"></div>
	    <div id="latlng"></div>
	</div>

	<script type="text/javascript">
	  function zeroPad(num, places) {
	    var zero = places - num.toString().length + 1;
	    return Array(+(zero > 0 && zero)).join("0") + num;
	  }
	  function getCenterLatLngText() {
	    var lat = map.getCenter().lat();
	    var lon = map.getCenter().lng();
	    var lats = lat >= 0.0 ? "n" : "s";
	    var lons = lon >= 0.0 ? "e" : "w";
	    lat = Math.abs(lat);
	    lon = Math.abs(lon);
	    var latd = Math.floor(lat);
	    var latm = Math.abs(lat-latd) * 60;
	    var lond = Math.floor(lon);
	    var lonm = Math.abs(lon-lond) * 60;
	    return lats + zeroPad(Math.abs(latd), 2) + "." +
	        String('000000'+latm.toFixed(3)).slice(-6) + " " +
	        lons + zeroPad(Math.abs(lond), 2) + "." +
	        String('000000'+lonm.toFixed(3)).slice(-6);
	  }
	  function centerChanged() {
	    var latlng = getCenterLatLngText();
	    document.getElementById('latlng').innerHTML = latlng;
	  }

	  var locations = [
	EOF

    i=0
    while ((i < Npts)); do
	LAT=${Lat[i]}
	LON=${Lon[i]}
	LABEL=${Label[i]}
	SYMBOL=${Symbol[i]}
	URL=${Url[i]}
	LLLABEL=${LLlabel[i]}
	if [ $LBLCOORDS = 1 ]; then
	    LABEL="$LABEL, `degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
	fi
	echo "    ['$LABEL', $LAT, $LON, '$SYMBOL', $i],"
	((i=i+1))
    done >> $OFILE

    cat <<-EOF >> $OFILE
    ];

    var map = new google.maps.Map(document.getElementById('map'), {
        tilt: 0,
        zoom: $ZOOM,
        center: new google.maps.LatLng($LATcenter, $LONcenter),
        mapTypeId: google.maps.MapTypeId.HYBRID
    });

    if ("$MAPSRC" == "gbike")
    {
        bicyclingLayer = new google.maps.BicyclingLayer();
        bicyclingLayer.setMap(map);
    }

    var infowindow = new google.maps.InfoWindow();

    var marker, i;

    if ("$DEFSYMBOL" == "hline" || "$DEFSYMBOL" == "vline"
        || "$DEFSYMBOL" == "xhair")
    {
        var ll = new google.maps.LatLng($LATcenter, $LONcenter);

        var hlineCoords = [
            google.maps.geometry.spherical.computeOffset(
                            ll, 2.0 * 1609.344, 90),
            google.maps.geometry.spherical.computeOffset(
                            ll, 2.0 * 1609.344, 270)
        ];
        var vlineCoords = [
            google.maps.geometry.spherical.computeOffset(
                            ll, 2.0 * 1609.344, 0),
            google.maps.geometry.spherical.computeOffset(
                            ll, 2.0 * 1609.344, 180)
        ];

        if ("$DEFSYMBOL" == "hline" || "$DEFSYMBOL" == "xhair")
        {
            var hline = new google.maps.Polyline({
                map: map,
                path: hlineCoords,
                strokeColor: "#FF0000",
                strokeOpacity: 1.0,
                strokeWeight: 2
              });
        }
        if ("$DEFSYMBOL" == "vline" || "$DEFSYMBOL" == "xhair")
        {
            var vline = new google.maps.Polyline({
                map: map,
                path: vlineCoords,
                strokeColor: "#FF0000",
                strokeOpacity: 1.0,
                strokeWeight: 2
              });
        }
    }

    for (i = 0; i < locations.length; i++)
    {  
        var oll;
        var ll = new google.maps.LatLng(locations[i][1], locations[i][2]);
        var symbol = locations[i][3];
        var symparms = symbol.split(",");
        if (0)
            marker = new google.maps.Marker({
                position: ll,
                title: locations[i][0],
                map: map
            });
        else
        {
            function color2hex(c)
            {
                var c2rgb = {
                    "red": "#ff0000",
                    "green": "#00ff00",
                    "blue": "#0000ff",
                    "orange": "#ffa500",
                    "yellow": "#ffff00",
                    "purple": "#800080",
                    "magenta":"#ff00ff",
                    "brown":"#a52a2a",
                    "lightgreen":"#90ee90",
                    "cyan":"#00ffff",
                    "gray":"#808080",
                    "white":"#ffffff"
                };
                return c2rgb[c.toLowerCase()] || "#fe7a6f";
            }
            var color = symparms[1] ? color2hex(symparms[1]) : "#fe7a6f";
            var text = locations.length <= 200 ? locations[i][4] + "" : "";
            marker = new StyledMarker({
                styleIcon: new StyledIcon(
                    (text == "" || i <= 99)
                        ? StyledIconTypes.MARKER : StyledIconTypes.BUBBLE,
                    { color: color, text: text }),
                position: ll,
                title: locations[i][0],
                map: map
            });
            // console.debug(text);
        }

        // if ("$DEFSYMBOL" == "gc" || symbol.match(/gc.*/))
        if (symbol.match(/gc.*/))
            var myRadius = new google.maps.Circle({
                map: map,
                center: ll,
                radius: 0.1 * 1609.344,
                fillColor: "#2b86f9",
                fillOpacity: 0.2,
                strokeColor: "#2b86f9",
                strokeOpacity: 1.0,
                strokeWeight: 1,
                clickable: false
        }); 
        // if ("$DEFSYMBOL" == "puzzle" || symbol.match(/puzzle.*/))
        if (symbol.match(/puzzle.*/))
            var myRadius = new google.maps.Circle({
                map: map,
                center: ll,
                radius: 2.0 * 1609.344,
                fillColor: "#2b86f9",
                fillOpacity: 0.2,
                strokeColor: "#2b86f9",
                strokeOpacity: 1.0,
                strokeWeight: 1,
                clickable: false
        }); 
        if (symbol.match(/circle.*/))
        {
            function km2m(str, p1, offset, totalstr) { return p1 * 1000; }
            function mi2m(str, p1, offset, totalstr) { return p1 * 1609.344; }
            function ft2m(str, p1, offset, totalstr) { return p1 * .3048; }
            function m2m(str, p1, offset, totalstr) { return p1 * 1; }
            symparms[2] = symparms[2].replace(/(.+)km/, km2m);
            symparms[2] = symparms[2].replace(/(.+)mi/, mi2m);
            symparms[2] = symparms[2].replace(/(.+)ft/, ft2m);
            symparms[2] = symparms[2].replace(/(.+)m/, m2m);
            symparms[3] = symparms[3] ? symparms[3] : 1;	// thick
            var myRadius = new google.maps.Circle({
                map: map,
                center: ll,
                radius: symparms[2] * 1,			// radius
                fillColor: symparms[1],				// color
                fillOpacity: 0.2,
                strokeColor: "#2b86f9",
                strokeOpacity: 1.0,
                strokeWeight: symparms[3],			// thick
                clickable: false
            }); 
        }

        if (symbol.match(/^line.*/) && i)
        {
            var lineCoords = [ oll, ll ];
            var line = new google.maps.Polyline({
                map: map,
                path: lineCoords,
                strokeColor: symparms[1],                   // color
                strokeOpacity: 1.0,
                strokeWeight: symparms[2]                   // thick
            });
        }

        if (symbol.match(/hline.*/) || symbol.match(/vline.*/) ||
            symbol.match(/xhair.*/))
        {
            var hlineCoords = [
                google.maps.geometry.spherical.computeOffset(
                                ll, 2.0 * 1609.344, 90),
                google.maps.geometry.spherical.computeOffset(
                                ll, 2.0 * 1609.344, 270)
            ];
            var vlineCoords = [
                google.maps.geometry.spherical.computeOffset(
                                ll, 2.0 * 1609.344, 0),
                google.maps.geometry.spherical.computeOffset(
                                ll, 2.0 * 1609.344, 180)
            ];

            symparms[2] = symparms[2] ? symparms[2] : 1;	// thick
            if (symbol.match(/hline.*/) || symbol.match(/xhair.*/))
            {
                var hline = new google.maps.Polyline({
                    map: map,
                    path: hlineCoords,
                    strokeColor: symparms[1],			// color
                    strokeOpacity: 1.0,
                    strokeWeight: symparms[2]			// thick
                  });
            }
            if (symbol.match(/vline.*/) || symbol.match(/xhair.*/))
            {
                var vline = new google.maps.Polyline({
                    map: map,
                    path: vlineCoords,
                    strokeColor: symparms[1],			// color
                    strokeOpacity: 1.0,
                    strokeWeight: symparms[2]			// thick
                  });
            }
        }

        google.maps.event.addListener(marker, 'click', (function(marker, i) {
            return function() {
                infowindow.setContent(locations[i][0]);
                infowindow.open(map, marker);
            }
        })(marker, i));

        oll = ll;
    }
    google.maps.event.addListener(map, 'center_changed', centerChanged);
    centerChanged();
  </script>
</body>
</html>
	EOF
    # 
    # Display it!
    #
    if [ $DOWWW = 1 ]; then
	put-rkkda -s rkkda/tmp $OFILE
	firefox "http://www.rkkda.com/tmp/$(basename $OFILE)"
    else
	firefox file:$OFILE
    fi
    exit
    ;;

50|leaflet)
    if [ "$OFILE" = "" ]; then
	# web only, RER 06/23/16
	DOWWW=1
	OFILE=xxx.html
	# local file
	DOWWW=0
	OFILE=/tmp/xxx.html;  #DOWWW=1
    fi
    echo $MAPSCALE
    ZOOM=16
    if [ "$MAPSCALE" -lt 65536000 ]; then ZOOM=2; fi
    if [ "$MAPSCALE" -lt 32768000 ]; then ZOOM=3; fi
    if [ "$MAPSCALE" -lt 16384000 ]; then ZOOM=4; fi
    if [ "$MAPSCALE" -lt 8192000 ]; then ZOOM=5; fi
    if [ "$MAPSCALE" -lt 4096000 ]; then ZOOM=6; fi
    if [ "$MAPSCALE" -lt 2048000 ]; then ZOOM=7; fi
    if [ "$MAPSCALE" -lt 1024000 ]; then ZOOM=8; fi
    if [ "$MAPSCALE" -lt 512000 ]; then ZOOM=9; fi
    if [ "$MAPSCALE" -lt 256000 ]; then ZOOM=10; fi
    if [ "$MAPSCALE" -lt 128000 ]; then ZOOM=11; fi
    if [ "$MAPSCALE" -lt 64000 ]; then ZOOM=12; fi
    if [ "$MAPSCALE" -lt 32000 ]; then ZOOM=13; fi
    if [ "$MAPSCALE" -lt 16000 ]; then ZOOM=14; fi
    if [ "$MAPSCALE" -lt 8000 ]; then ZOOM=15; fi
    if [ "$MAPSCALE" -lt 4000 ]; then ZOOM=16; fi
    if [ "$MAPSCALE" -lt 2000 ]; then ZOOM=17; fi
    if [ "$MAPSCALE" -lt 1000 ]; then ZOOM=18; fi
    if [ "$MAPSCALE" -lt 500 ]; then ZOOM=19; fi
    cat <<-EOF > $OFILE
	<!DOCTYPE html>
	<html>
	<!-- $0 $ARGS -->
	<head> 
	  <meta http-equiv="content-type" content="text/html; charset=UTF-8" /> 
	  <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
	  <title>geo-map ...</title> 
	  <style type="text/css">
	      html { height: 100% }
	      body { height: 100%; margin: 0px; padding: 0px }
	      #map_canvas { height: 100% }
	      div#xxx { position: relative; }
	      div#latlng {
      		position: absolute;
      		bottom: 0;
      		left: 33%;
      		opacity: 0.8;
      		background-color: #ffffff;
      		z-index: 90000;
	      }
	      .marker-number {
      		transform: rotate(-45deg);
      		color: black;
      		left: 8px;
      		top: 5px;
      		position: absolute;
	      }
	      div#crosshair {
	        position: absolute;
	        top: 50%;
	        margin-top: -10px;
	        height: 19px;
	        width: 19px;
	        left: 50%;
	        margin-left: -8px;
	        display: block;
	        background: url(data:image/gif;base64,R0lGODlhEwATAKEBAAAAAP///////////yH5BAEKAAIALAAAAAATABMAAAIwlI+pGhALRXuRuWopPnOj7hngEpRm6ZymAbTuC7eiitJlNHr5tmN99cNdQpIhsVIAADs=);
	        background-position: center center;
	        background-repeat: no-repeat;
			z-index: 90000;
	      }
	      #map { height: 100%; }
	  </style>
          <link rel="stylesheet" href="https://unpkg.com/leaflet@1.3.4/dist/leaflet.css" integrity="sha512-puBpdR0798OZvTTbP4A8Ix/l+A4dHDD0DGqYW6RQ+9jxkRFclaxxQb/SJAWZfWAkuyeQUytO7+7N4QKrDh+drA=="
	    crossorigin="" />
	  <script src='https://npmcdn.com/@turf/turf/turf.min.js'></script>
	  <script src="https://unpkg.com/leaflet@1.3.4/dist/leaflet.js" integrity="sha512-nMMmRyTVoLYqjP9hrbed9S+FzjZHW5gY1TWCHA5ckwXZBadntCNs8kEqAWdrb9O7rxbCaA4lKTIWjDXZxflOcA=="
            crossorigin="">
	  </script>
	</head>
	<body>
	  <div id="xxx" style="width: 100%; height: 100%">
	    <div id="latlng"></div>
	    <div id="crosshair"></div>
            <div id="map" style="width: 100%; height: 100%;"></div>
	  </div>

	  <script type="text/javascript">
	    function zeroPad(num, places) {
	      var zero = places - num.toString().length + 1;
	      return Array(+(zero > 0 && zero)).join("0") + num;
	    }

    function generateIcon(number, color) {
      const markerHtmlStyles = "'background-color: " + color + ";width: 1.75rem;height: 1.75rem;display: block;position: relative;border-radius: 5rem 5rem 0; transform: translate(-30px, -30px) rotate(45deg);transform-origin: right bottom;border: 1px solid #000000;color: black;'";

      if (number == -1)
        return L.divIcon({
          className: "custom-pin",
          iconAnchor: [0, 0],
          labelAnchor: [-6, 0],
          popupAnchor: [-8, -15],
          html: "<span style=" + markerHtmlStyles + "></span>"
        });
      else
        return L.divIcon({
          className: "custom-pin",
          iconAnchor: [0, 0],
          labelAnchor: [-6, 0],
          popupAnchor: [-8, -15],
          html: "<span style=" + markerHtmlStyles + "><div class='marker-number'>" + number +"</div></span>"
        });
    }

    function getInitialZoom() {
      let totalLat = 0;
      let totalLon = 0;
      locations.forEach(function (locationArray) {
        totalLat += locationArray[1];
        totalLon += locationArray[2];
      });
      return [totalLat / locations.length, totalLon / locations.length];
    }

    function km2m(str, p1, offset, totalstr) {
      return p1 * 1000;
    }

    function mi2m(str, p1, offset, totalstr) {
      return p1 * 1609.344;
    }

    function ft2m(str, p1, offset, totalstr) {
      return p1 * 0.3048;
    }

    function m2m(str, p1, offset, totalstr) {
      return p1 * 1;
    }

    function color2hex(c) {
      let c2rgb = {
        red: "#ff0000",
        green: "#00ff00",
        blue: "#0000ff",
        orange: "#ffa500",
        yellow: "#ffff00",
        purple: "#800080",
        magenta: "#ff00ff",
        brown: "#a52a2a",
        lightgreen: "#90ee90",
        cyan: "#00ffff",
        gray: "#808080",
        white: "#ffffff"
      };
      return c2rgb[c.toLowerCase()] || "#fe7a6f";
    }

    function getCenterLatLngText() {
      var lat = map.getCenter().lat;
      var lon = map.getCenter().lng;
      var lats = lat >= 0.0 ? "n" : "s";
      var lons = lon >= 0.0 ? "e" : "w";
      lat = Math.abs(lat);
      lon = Math.abs(lon);
      var latd = Math.floor(lat);
      var latm = Math.abs(lat - latd) * 60;
      var lond = Math.floor(lon);
      var lonm = Math.abs(lon - lond) * 60;
      return (
        lats +
        zeroPad(Math.abs(latd), 2) +
        "." +
        String("000000" + latm.toFixed(3)).slice(-6) +
        " " +
        lons +
        zeroPad(Math.abs(lond), 2) +
        "." +
        String("000000" + lonm.toFixed(3)).slice(-6)
      );
    }

    function centerChanged() {
      var latlng = getCenterLatLngText();
      document.getElementById("latlng").innerHTML = latlng;
    }

	  var locations = [
	EOF

    i=0
    while ((i < Npts)); do
	LAT=${Lat[i]}
	LON=${Lon[i]}
	LABEL=${Label[i]}
	SYMBOL=${Symbol[i]}
	URL=${Url[i]}
	LLLABEL=${LLlabel[i]}
	if [ $LBLCOORDS = 1 ]; then
	    LABEL="$LABEL, `degdec2mindec $LAT ns` `degdec2mindec $LON ew`"
	fi
	echo "    ['$LABEL', $LAT, $LON, '$SYMBOL', $i],"
	((i=i+1))
    done >> $OFILE

    cat <<-EOF >> $OFILE
    ];

    const largeDataset = locations.length > 99 ? true : false
    let map = L.map("map", {
        preferCanvas: true,
        zoomControl: false
      }).setView(getInitialZoom(), $ZOOM);
    new L.Control.Zoom({ position: 'bottomright' }).addTo(map);

    let OSMStreets = L.tileLayer(
      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
    ).addTo(map);
    let ESRISatellite = L.tileLayer(
      "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
    );
    let CartoDBVoyager = L.tileLayer(
      "https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}{r}.png"
    );
    let Wikimedia = L.tileLayer(
      "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}{r}.png"
    );

    let basemapControl = {
      "OSM Streets": OSMStreets,
      "ESRI Satellite": ESRISatellite,
      "Carto DB Voyager": CartoDBVoyager,
      Wikimedia: Wikimedia
    };

    L.control.layers(basemapControl).addTo(map);
    let oll;
    locations.forEach(function (locationArray) {
      let marker
      let [coordinateString, lat, lon, symbolString, number] = locationArray;
      let symbolParams = symbolString.split(",");
      let color = symbolParams[1] ? color2hex(symbolParams[1]) : "#fe7a6f";
      // switch(false){	
      switch(largeDataset){
      case true:
        marker = L.circleMarker([lat, lon],
        { color: "black", fillColor: color, radius: 7, weight: 1 }).addTo(map);
        break;
      case false:
        let icon = generateIcon(largeDataset ? -1 : number, color);
        marker = L.marker([lat, lon], { icon: icon }).addTo(map);
        break;
      }
      marker.bindPopup(coordinateString);
      if (symbolString.match(/gc.*/)) {
        let options = {
          radius: 0.1 * 1609.344,
          fillColor: "#2b86f9",
          fillOpacity: 0.2,
          color: "#2b86f9",
          opacity: 1.0,
          weight: 1
        };
        L.circle([lat, lon], options).addTo(map);
      }
      if (symbolString.match(/puzzle.*/)) {
        let options = {
          radius: 2 * 1609.344,
          fillColor: "#2b86f9",
          fillOpacity: 0.2,
          color: "#2b86f9",
          opacity: 1.0,
          weight: 1
        };
        L.circle([lat, lon], options).addTo(map);
      }
      if (symbolString.match(/circle.*/)) {
        symbolParams[2] = symbolParams[2].replace(/(.+)km/, km2m);
        symbolParams[2] = symbolParams[2].replace(/(.+)mi/, mi2m);
        symbolParams[2] = symbolParams[2].replace(/(.+)ft/, ft2m);
        symbolParams[2] = symbolParams[2].replace(/(.+)m/, m2m);
        symbolParams[3] = symbolParams[3] ? symbolParams[3] : 1;

        let options = {
          radius: symbolParams[2] * 1,
          fillColor: symbolParams[1],
          fillOpacity: 0.2,
          color: "#2b86f9",
          opacity: 1.0,
          weight: symbolParams[3]
        };
        L.circle([lat, lon], options).addTo(map);
      }
      if (symbolString.match(/^line.*/) && oll != undefined) {
        let options = {
          color: Object.is(symbolParams[1], undefined)
            ? "#000000"
            : symbolParams[1],
          opacity: 1.0,
          weight: Object.is(symbolParams[2], undefined) ? 3 : symbolParams[2]
        };
        let line = L.polyline([oll, [lat, lon]], options).addTo(map);
      }
      if (
        symbolString.match(/hline.*/) ||
        symbolString.match(/vline.*/) ||
        symbolString.match(/xhair.*/)
      ) {
        symbolParams[2] = symbolParams[2] ? symbolParams[2] : 3;
        let point = turf.point([lon, lat]);
        let calcOptions = {
          units: "meters"
        };
        let options = {
          color: symbolParams[1] ? symbolParams[1] : '#3388ff',
          opacity: 1,
          weight: symbolParams[2]
        }
        if (symbolString.match(/hline.*/) || symbolString.match(/xhair.*/)) {
          let eastDestination = turf.destination(
            point,
            2.0 * 1609.344,
            90,
            calcOptions
          )
          let westDestination = turf.destination(
            point,
            2.0 * 1609.344,
            -90,
            calcOptions
          );
          let polyLine = L.polyline([eastDestination.geometry.coordinates.reverse(), westDestination.geometry.coordinates.reverse()], options).addTo(map)
        }
        if (symbolString.match(/vline.*/) || symbolString.match(/xhair.*/)) {
          let northDestination = turf.destination(
            point,
            2.0 * 1609.344,
            180,
            calcOptions
          );
          let southDestination = turf.destination(
            point,
            2.0 * 1609.344,
            0,
            calcOptions
          );
          let polyLine = L.polyline([southDestination.geometry.coordinates.reverse(), northDestination.geometry.coordinates.reverse()], options).addTo(map)
        }
      }
      oll = [lat, lon];
    });
    map.on("move", centerChanged);
    centerChanged()
   
  </script>
</body>
</html>
	EOF
    # 
    # Display it!
    #
    if [ $DOWWW = 1 ]; then
	put-rkkda -s rkkda/tmp $OFILE
	firefox "http://www.rkkda.com/tmp/$(basename $OFILE)"
    else
	firefox file:$OFILE
    fi
    exit
    ;;

*)
    error "Unknown map source '$MAPSRC'"
    ;;
esac

if [ ! -s $IMAP ]; then
    error "Unable to fetch the map"
fi

if [ "$MARKER" = 1 ]; then
    if [ "$IMAGEMAP" != "" ]; then
	usemap_tag=$(echo "$OFILE" | sed -e "s/[.].*//" -e "s/.*[/]//")
	usemap_file="$IMAGEMAP"
	usemap_append=0
	case "$IMAGEMAP" in
	+*)	usemap_append=1
		usemap_file=$(echo "$IMAGEMAP" | sed -e "s/^[+]//")
		;;
	esac
	if [ $usemap_append = 0 ]; then
	    echo "<HTML><BODY>" > "$usemap_file"
	    printf '<IMG SRC="' >> "$usemap_file"
	    printf "$OFILE" >> "$usemap_file"
	    printf '" USEMAP="#' >> "$usemap_file"
	    printf "$usemap_tag" >> "$usemap_file"
	    echo '">' >> "$usemap_file"
	fi
	printf '<MAP NAME="' >> "$usemap_file"
	printf "$usemap_tag" >> "$usemap_file"
	echo '">' >> "$usemap_file"
    fi
    # create full convert input as pipe
    i=0
    while ((i < Npts )); do
	LAT=${Lat[i]}
	LON=${Lon[i]}
	LABEL=${Label[i]}
	SYMBOL=${Symbol[i]}
	URL=${Url[i]}
	LLLABEL=${LLlabel[i]}
	echo "$LON,$LAT^$SYMBOL^$LABEL^$URL^$LLLABEL"
	i=$(($i+1))
    done \
    | tiger2cvt $LATcenter $LONcenter $w $h $MAPSCALE "$TITLE" "$FOOTER" \
    | awk -vmaxsize=30000 '
	{
	    if (length(cmd) + length($0) > maxsize)
	    {
		print cmd
		cmd = ""
	    }
	    cmd = cmd " " $0
	}
	END {print cmd}' \
    | while read XX; do
	eval dbgcmd convert $XX $IMAP $OMAP
	if [ `uname` = Darwin ]; then
	    cp -p -R $OMAP $IMAP
	else
	    cp -a $OMAP $IMAP
	fi
    done
    if [ "$IMAGEMAP" != "" ]; then
	echo "</MAP>" >> "$usemap_file"
	if [ $usemap_append = 0 ]; then
	    echo "</BODY></HTML>" >> "$usemap_file"
	fi
    fi
    map="$OMAP"
else
    map="$IMAP"
fi

# Calculate coordinates of the map corners
meters=`echo "$MAPSCALE $h * $PIXELFACT /p" | dc`
dlat=`calc_latlon dlat $LATcenter $LONcenter $meters 0`
meters=`echo "$MAPSCALE $w * $PIXELFACT /p" | dc`
dlon=`calc_latlon dlon $LATcenter $LONcenter $meters 90`

iscale=`awk "BEGIN{print int($MAPSCALE+0.5)}"`

ULlat=` echo "scale=6; $LATcenter + ($dlat/2)" | bc`
ULlon=` echo "scale=6; $LONcenter - ($dlon/2)" | bc`
LRlat=` echo "scale=6; $LATcenter - ($dlat/2)" | bc`
LRlon=` echo "scale=6; $LONcenter + ($dlon/2)" | bc`

if [ "$POLY" != "" ]; then
    > $POLY
    echo "$ULlat $ULlon" >> $POLY
    echo "$ULlat $LRlon" >> $POLY
    echo "$LRlat $LRlon" >> $POLY
    echo "$LRlat $ULlon" >> $POLY
    echo "$ULlat $ULlon" >> $POLY
fi

if [ "$OFILE" = "" ]; then
    # Display map coords
    verbose 1 "Center:    	$LATcenter	$LONcenter	$iscale:1	`degdec2mindec $LATcenter ns`	`degdec2mindec $LONcenter ew`"
    verbose 1 "UpperLeft: 	$ULlat	$ULlon	`degdec2mindec $ULlat ns`	`degdec2mindec $ULlon ew`"
    verbose 1 "LowerRight:	$LRlat	$LRlon	`degdec2mindec $LRlat ns`	`degdec2mindec $LRlon ew`"

    # View map
    if which mspaint.exe 2>/dev/null; then
	# Running under CygWin...
	mspaint `cygpath -w $map`
    elif which xv 2>/dev/null; then
	xv $map
    elif [ `uname` = "Darwin" ]; then
	open -a /Applications/Preview.app/ $map
    elif which eog 2>/dev/null; then
	debug 0 "You need to install 'xv', the best image viewer for Unix/Linux"
	eog $map
    elif which display 2>/dev/null; then
	debug 0 "You need to install 'xv', the best image viewer for Unix/Linux"
	display $map
    else
	DEBUG=1
	debug 1 "You need to install 'xv', the best image viewer for Unix/Linux"
	debug 1 "http://fr2.rpmfind.net/linux/rpm2html/search.php?query=xv"
    fi
else
    # GpsDrive map_koord.txt line...
    verbose 1 "$OFILE $LATcenter $LONcenter $iscale	# $ULlat $ULlon $LRlat $LRlon"

    # Possible format conversion here
    if [ "" != "$TITLE" -o "" != "$FOOTER" ]; then
	convert -comment "|$TITLE|$FOOTER|" $map $OFILE
    else
	convert $map $OFILE
    fi
    if [ $DOWWW = 1 ]; then
	put-rkkda -s rkkda/tmp $OFILE
	echo "http://www.rkkda.com/tmp/$(basename $OFILE)"
    fi
fi

# <IMG SRC="image.gif" USEMAP="#nwelogoareas" border="0">
# <MAP NAME="nwelogoareas">
#   <AREA SHAPE="rect" COORDS="86,35,290,63" HREF="http://web.nwe.ufl.edu/">
#   <AREA SHAPE="rect" COORDS="44,68,360,94" HREF="http://sierraclub.org/">
# </MAP>
