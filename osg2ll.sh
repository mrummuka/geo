#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - British National Grid to Lat/Lon

SYNOPSIS
	`basename $PROGNAME` [options] [letters] easting northing

DESCRIPTION
	British National Grid, a.k.a. Ordnance Survey Grid to Lat/Lon.

EXAMPLE
	Convert to DegDec:

	    $ osg2ll 338937 443358
	    Muggleton:      53.882610 -2.929045
	    Hannah:         53.882801 -2.930417

	    $ osg2ll SD 38937 443358
	    Muggleton:      53.882610 -2.929045
	    Hannah:         53.882801 -2.930417

	Convert to RickDec:

	    $ osg2ll -orickdec 338937 443358
	    Muggleton:      n53.52.957 w02.55.743
	    Hannah:         n53.52.968 w02.55.825

OPTIONS
	-l              Print latitude only
	-L              Print longitude only
	-odegdec        Print lat/lon in DegDec format (default)
	-omindec        Print lat/lon in MinDec format
	-orickdec       Print lat/lon in dotted MinDec format
	-odms           Print lat/lon in DMS format
	-D lvl	Debug level

SEE ALSO
	http://www.carabus.co.uk/ngr_ll.html

	http://www.hannahfry.co.uk/blog/2012/02/01/converting-british-national-grid-to-latitude-and-longitude-ii
EOF

	exit 1
}

#include "geo-common"

#
#       Report an error and exit
#
error() {
	echo "`basename $PROGNAME`: $1" >&2
	exit 1
}

debug() {
	if [ $DEBUG -ge $1 ]; then
	    echo "`basename $PROGNAME`: $2" >&2
	fi
}

#
#       Process the options
#
DEBUG=0
FMT=degdec
LatOnly=0
LonOnly=0
while getopts "lLo:D:h?" opt
do
	case $opt in
	l)      LatOnly=1;;
	L)      LonOnly=1;;
	o)      FMT="$OPTARG";;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$#" in
3)
	LETS=$1
	EAST=$2
	NORTH=$3
        ;;
2)
	EAST=$1
	NORTH=$2
        ;;
*)
        usage
        ;;
esac

#
#	Main Program
#
awk -v LETS="$LETS" -v EAST=$EAST -v NORTH=$NORTH \
    -v FMT=$FMT -v LatOnly=$LatOnly -v LonOnly=$LonOnly '
# http://www.dorcus.co.uk/carabus/ll_ngr.html
# http://www.dorcus.co.uk/carabus/ngr_ll.html
# http://hannahfry.co.uk/2012/02/01/converting-british-national-grid-to-latitude-and-longitude-ii/
function pow(a, b)      { return a ^ b }
function tan(x)         { return sin(x)/cos(x) }
function abs(x) { return (((x < 0) ? -x : x) + 0); }
function fabs(x) { return (((x < 0.0) ? -x : x) + 0.0); }
function ConvertToString(x)         { return sprintf("%c", x) }
function Number(x)         { return x }
function rad2deg(angle)
{
    return angle * 57.29577951308232        # angle / PI * 180
}
function outfmt(coord, lets,    deg, min, fmin, sec)
{
    let = (coord >= 0) ? substr(lets,1,1) : substr(lets,2,1)

    if (FMT == "degdec")
        printf("%f", coord)
    else if (FMT == "mindec")
    {
        deg = int(coord)
        min = fabs(coord - deg) * 60.0
        printf("%c%d %s%.3f", let, abs(deg), (min < 10) ? "0" : "", min)
    }
    else if (FMT == "rickdec")
    {
        deg = int(coord)
        min = fabs(coord - deg) * 60.0
        printf("%c%02d.%s%.3f", let, abs(deg), (min < 10) ? "0" : "", min)
    }
    else if (FMT == "dms")
    {
        deg = int(coord)
        fmin = fabs(coord - deg) * 60.0
        min = int(fmin)
        sec = int( (fmin-min) * 60.0 )
        printf("%d %02d %02d", deg, min, sec)
    }
    else
    {
        print "Format not implemented yet"
        exit
    }
}
function Marc(bf0, n, phi0, phi)
    {
     return bf0 * (((1 + n + ((5 / 4) * (n * n)) + ((5 / 4) * (n * n * n))) \
	* (phi - phi0)) \
        - (((3 * n) + (3 * (n * n)) + ((21 / 8) * (n * n * n))) * \
	(sin(phi - phi0)) * (cos(phi + phi0))) \
        + ((((15 / 8) * (n * n)) + ((15 / 8) * (n * n * n))) * \
	(sin(2 * (phi - phi0))) * (cos(2 * (phi + phi0)))) \
        - (((35 / 24) * (n * n * n)) * (sin(3 * (phi - phi0))) * \
	(cos(3 * (phi + phi0)))));
    }
function InitialLat(north, n0, af0, phi0, n, bf0)
{
    phi1 = ((north - n0) / af0) + phi0;
    M = Marc(bf0, n, phi0, phi1);
    phi2 = ((north - n0 - M) / af0) + phi1;
    ind = 0;
    #max 20 iterations in case of error
    while ((fabs(north - n0 - M) > 0.00001) && (ind < 20))
    {  
	ind = ind + 1;
	phi2 = ((north - n0 - M) / af0) + phi1;
	M = Marc(bf0, n, phi0, phi2);
	phi1 = phi2;
    }
    return phi2
}

# converts lat and lon (OSGB36)  to OS 6 figure northing and easting
function NEtoLL(east, north) 
{
    # converts NGR easting and nothing to lat, lon.
    # input metres, output radians
    nX = Number(north);
    eX = Number(east);
    a = 6377563.396;       // OSGB semi-major
    b = 6356256.909;        // OSGB semi-minor
    e0 = 400000;           // OSGB easting of false origin
    n0 = -100000;          // OSGB northing of false origin
    f0 = 0.9996012717;     // OSGB scale factor on central meridian
    e2 = 0.0066705397616;  // OSGB eccentricity squared
    lam0 = -0.034906585039886591;  // OSGB false east
    phi0 = 0.85521133347722145;    // OSGB false north
    af0 = a * f0;
    bf0 = b * f0;
    n = (af0 - bf0) / (af0 + bf0);
    Et = east - e0;
    phid = InitialLat(north, n0, af0, phi0, n, bf0);
    nu = af0 / (sqrt(1 - (e2 * (sin(phid) * sin(phid)))));
    rho = (nu * (1 - e2)) / (1 - (e2 * (sin(phid)) * (sin(phid))));
    eta2 = (nu / rho) - 1;
    tlat2 = tan(phid) * tan(phid);
    tlat4 = pow(tan(phid), 4);
    tlat6 = pow(tan(phid), 6);
    clatm1 = pow(cos(phid), -1);
    VII = tan(phid) / (2 * rho * nu);
    VIII = (tan(phid) / (24 * rho * (nu * nu * nu))) * (5 + (3 * tlat2) + eta2 - (9 * eta2 * tlat2));
    IX = ((tan(phid)) / (720 * rho * pow(nu, 5))) * (61 + (90 * tlat2) + (45 * pow(tan(phid), 4) ));
    phip = (phid - ((Et * Et) * VII) + (pow(Et, 4) * VIII) - (pow(Et, 6) * IX)); 
    X = pow(cos(phid), -1) / nu;
    XI = (clatm1 / (6 * (nu * nu * nu))) * ((nu / rho) + (2 * (tlat2)));
    XII = (clatm1 / (120 * pow(nu, 5))) * (5 + (28 * tlat2) + (24 * tlat4));
    XIIA = clatm1 / (5040 * pow(nu, 7)) * (61 + (662 * tlat2) + (1320 * tlat4) + (720 * tlat6));
    lambdap = (lam0 + (Et * X) - ((Et * Et * Et) * XI) + (pow(Et, 5) * XII) - (pow(Et, 7) * XIIA));
    # geo = { latitude: phip, longitude: lambdap };
    lat = rad2deg(phip)
    lon = rad2deg(lambdap)
        if (!LatOnly && !LonOnly)
        {
            outfmt(lat, "ns")
            printf(" ")
            outfmt(lon, "ew")
            printf("\n")
        }
        else
        {
            if (LatOnly)
            {
                outfmt(lat, "ns")
                printf("\n")
            }
            if (LonOnly)
            {
                outfmt(lon, "ew")
                printf("\n")
            }
        }
    return(geo);
} 

function OSGB36toWGS84(E, N) {
    #E, N are the British national grid coordinates - eastings and northings
    a = 6377563.396     #The Airy 180 semi-major and semi-minor axes used for OSGB36 (m)
    b = 6356256.909     #The Airy 180 semi-major and semi-minor axes used for OSGB36 (m)
    F0 = 0.9996012717                   #scale factor on the central meridian
    lat0 = 49*pi/180                    #Latitude of true origin (radians)
    lon0 = -2*pi/180                    #Longtitude of true origin and central meridian (radians)
    N0 = -100000            #Northing & easting of true origin (m)
    E0 =  400000            #Northing & easting of true origin (m)
    e2 = 1 - (b*b)/(a*a)                #eccentricity squared
    n = (a-b)/(a+b)

    #Initialise the iterative variables
    lat = lat0
    M = 0

    while (N-N0-M >= 0.00001) #Accurate to 0.01mm
    {
        lat = (N-N0-M)/(a*F0) + lat;
        M1 = (1 + n + (5./4)*n**2 + (5./4)*n**3) * (lat-lat0)
        M2 = (3*n + 3*n**2 + (21./8)*n**3) * sin(lat-lat0) * cos(lat+lat0)
        M3 = ((15./8)*n**2 + (15./8)*n**3) * sin(2*(lat-lat0)) * cos(2*(lat+lat0))
        M4 = (35./24)*n**3 * sin(3*(lat-lat0)) * cos(3*(lat+lat0))
        #meridional arc
        M = b * F0 * (M1 - M2 + M3 - M4)          
    }

    #transverse radius of curvature
    nu = a*F0/sqrt(1-e2*sin(lat)**2)

    #meridional radius of curvature
    rho = a*F0*(1-e2)*(1-e2*sin(lat)**2)**(-1.5)
    eta2 = nu/rho-1

    secLat = 1./cos(lat)
    VII = tan(lat)/(2*rho*nu)
    VIII = tan(lat)/(24*rho*nu**3)*(5+3*tan(lat)**2+eta2-9*tan(lat)**2*eta2)
    IX = tan(lat)/(720*rho*nu**5)*(61+90*tan(lat)**2+45*tan(lat)**4)
    X = secLat/nu
    XI = secLat/(6*nu**3)*(nu/rho+2*tan(lat)**2)
    XII = secLat/(120*nu**5)*(5+28*tan(lat)**2+24*tan(lat)**4)
    XIIA = secLat/(5040*nu**7)*(61+662*tan(lat)**2+1320*tan(lat)**4+720*tan(lat)**6)
    dE = E-E0

    #These are on the wrong ellipsoid currently: Airy1830. (Denoted by _1)
    lat_1 = lat - VII*dE**2 + VIII*dE**4 - IX*dE**6
    lon_1 = lon0 + X*dE - XI*dE**3 + XII*dE**5 - XIIA*dE**7

    #Want to convert to the GRS80 ellipsoid. 
    #First convert to cartesian from spherical polar coordinates
    H = 0 #Third spherical coord. 
    x_1 = (nu/F0 + H)*cos(lat_1)*cos(lon_1)
    y_1 = (nu/F0+ H)*cos(lat_1)*sin(lon_1)
    z_1 = ((1-e2)*nu/F0 +H)*sin(lat_1)

    #Perform Helmut transform (to go between Airy 1830 (_1) and GRS80 (_2))
    s = -20.4894*10**-6 #The scale factor -1
    tx = 446.448	#The translations along x,y,z axes respectively
    ty = -125.157	#The translations along x,y,z axes respectively
    tz = +542.060	#The translations along x,y,z axes respectively
    rxs = 0.1502	#The rotations along x,y,z respectively, in seconds
    rys = 0.2470	#The rotations along x,y,z respectively, in seconds
    rzs = 0.8421	#The rotations along x,y,z respectively, in seconds
    rx = rxs*pi/(180*3600.)	#In radians
    ry = rys*pi/(180*3600.)	#In radians
    rz = rzs*pi/(180*3600.)	#In radians
    x_2 = tx + (1+s)*x_1 + (-rz)*y_1 + (ry)*z_1
    y_2 = ty + (rz)*x_1  + (1+s)*y_1 + (-rx)*z_1
    z_2 = tz + (-ry)*x_1 + (rx)*y_1 +  (1+s)*z_1

    #Back to spherical polar coordinates from cartesian
    #Need some of the characteristics of the new ellipsoid    
    a_2 = 6378137.000	#The GSR80 semi-major and semi-minor axes used for WGS84(m)
    b_2 = 6356752.3141	#The GSR80 semi-major and semi-minor axes used for WGS84(m)
    e2_2 = 1- (b_2*b_2)/(a_2*a_2)   #The eccentricity of the GRS80 ellipsoid
    p = sqrt(x_2**2 + y_2**2)

    #Lat is obtained by an iterative proceedure:   
    lat = atan2(z_2,(p*(1-e2_2))) #Initial value
    latold = 2*pi
    while (abs(lat - latold) > 10^-16)
    { 
        tmp = lat
        lat = latold
        latold = tmp
        nu_2 = a_2/sqrt(1-e2_2*sin(latold)**2)
        lat = atan2(z_2+e2_2*nu_2*sin(latold), p)
	#print lat, latold, lat - latold
    }

    #Lon and height are then pretty easy
    lon = atan2(y_2,x_2)
    H = p/cos(lat) - nu_2

    #Uncomment this line if you want to print the results
    #print [(lat-lat_1)*180/pi, (lon - lon_1)*180/pi]

    #Convert to degrees
    lat = lat*180/pi
    lon = lon*180/pi
        if (!LatOnly && !LonOnly)
        {
            outfmt(lat, "ns")
            printf(" ")
            outfmt(lon, "ew")
            printf("\n")
        }
        else
        {
            if (LatOnly)
            {
                outfmt(lat, "ns")
                printf("\n")
            }
            if (LonOnly)
            {
                outfmt(lon, "ew")
                printf("\n")
            }
        }
    # return lat, lon
}

BEGIN {
    pi = 3.14159265359
    if (1)
    {
	printf "Muggleton:	"
	NEtoLL(EAST, NORTH)
    }
    if (1)
    {
	if (LETS != "")
	{
	    LETS = toupper(LETS)
	    gsub(/[^A-Z]/, "", LETS)
	    if (length(LETS) != 2)
	    {
		print "Exactly two letters are needed!"
		exit
	    }
	    t1 = index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", substr(LETS, 1, 1)) - 1
	    if (t1 > 8)
		t1 = t1 -1;
	    t2 = int(t1 / 5);
	    NORTH = NORTH + 500000 * (3 - t2);
	    EAST = EAST + 500000 * (t1 - 5 * t2 - 2);

	    t1 = index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", substr(LETS, 2, 1)) - 1
	    if (t1 > 8)
		t1 = t1 - 1;
	    t2 = int(t1 / 5);
	    NORTH = NORTH + 100000 * ( 4 - t2);
	    EAST = EAST + 100000 * ( t1 - 5 * t2);
	}
	printf "Hannah: 	"
	OSGB36toWGS84(EAST, NORTH)
    }
}
'
