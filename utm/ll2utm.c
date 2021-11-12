#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include "ups.c"
#include "tm.c"
#include "utm.c"

/*
 * Global option flags
 */
int	Debug = 0;
int	Easting = 0;
int	Northing = 0;
int	MultiLine = 0;
int	LatBand = 0;
int	Zone = 0;

void
debug(int level, char *fmt, ...)
{
	va_list ap;

	if (Debug < level)
		return;
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
}

int
error(int fatal, char *fmt, ...)
{
	va_list ap;

	fprintf(stderr, fatal ? "Error: " : "Warning: ");
	if (errno)
	    fprintf(stderr, "%s: ", strerror(errno));
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	if (fatal > 0)
	    exit(fatal);
	else
	{
	    errno = 0;
	    return (fatal);
	}
}

void
usage(void)
{
	fprintf(stderr,
"NAME\n"
"	ll2utm - Convert lat/lon to Universal Transverse Mercator (UTM) format\n"
"SYNOPSYS\n"
"	ll2utm [options] lat lon\n"
"\n"
"	Convert WGS-84 latitude/longitude to UTM.\n"
"	See examples for the input formats which are acceptable.\n"
"\n"
"OPTIONS\n"
"       -e          Print easting only.  May be combined with -n.\n"
"       -n          Print northing only.  May be combined with -e.\n"
"       -m          Print multi-line results (one field per line)\n"
"       -D lvl      Set Debug level [%d]\n"
"\n"
"EXAMPLES\n"
"	All of the below are equivalent and output this result...\n"
"		15 T 459594 4928460\n"
"\n"
"	# DegDec format\n"
"	\n"
"	 ll2utm 44.508333 -93.508333\n"
"	 ll2utm N44.508333 W93.508333\n"
"	\n"
"	# Rick style MinDec format\n"
"	\n"
"	 ll2utm N 44.30.50 W 93.30.50\n"
"	 ll2utm N44.30.50 W93.30.50\n"
"	 ll2utm 44.30.50 -93.30.50\n"
"	 ll2utm \"N 44.30.50\" \"W 93.30.50\"\n"
"	 ll2utm \"N44.30.50\" \"W93.30.50\"\n"
"	 ll2utm \"44.30.50\" \"-93.30.50\"\n"
"	\n"
"	# Space separated MinDec format\n"
"	\n"
"	 ll2utm N 44 30.50 W 93 30.50\n"
"	 ll2utm N44 30.50 W93 30.50\n"
"	 ll2utm 44 30.50 -93 30.50\n"
"	 ll2utm \"N 44 30.50\" \"W 93 30.50\"\n"
"	 ll2utm \"N44 30.50\" \"W93 30.50\"\n"
"	 ll2utm \"44 30.50\" \"-93 30.50\"\n"
"	\n"
"	# gc.com web page cut and paste format\n"
"	\n"
"	 ll2utm  N 44° 30.50 W 093° 30.50\n"
"	 ll2utm \"N 44° 30.50\" \"W 093° 30.50\"\n"
"	\n"
"	# DMS format\n"
"	\n"
"	 ll2utm 44 30 30 W93 30 30\n"
"	 ll2utm 44 30 30 -93 30 30\n"
"	 ll2utm \"44 30 30\" \"W93 30 30\"\n"
"	 ll2utm \"44 30 30\" \"-93 30 30\"\n"
"	 ll2utm 44 30 29.99999999 W93 30 29.99999999\n"
"	 ll2utm 44 30 29.99999999 -93 30 29.99999999\n"
	, Debug
	);

	exit(1);
}

double
getll(char *str)
{
    int		i1,i2,i3;
    double	f;
    int		n;
    char 	*p;
    double	neg = 1;

    if (*str == 'N' || *str == 'n') { neg = 1; ++str; }
    else if (*str == 'S' || *str == 's') { neg = -1; ++str; }
    else if (*str == 'W' || *str == 'w') { neg = -1; ++str; }
    else if (*str == 'E' || *str == 'e') { neg = 1; ++str; }
    else if (*str == '-') { neg = -1; ++str; }

    while (*str == ' ')
	++str;

    n = sscanf(str, "%d.%d.%d", &i1, &i2, &i3);
    if (n == 3)
    {
	debug(1, "Rick style MinDec <%s>\n", str);
	p = strchr(str, '.'); *p++ = 0;
	return neg * (atof(str) + atof(p)/60.0);
    }
    n = sscanf(str, "%d %d.%d", &i1, &i2, &i3);
    if (n == 3)
    {
	debug(1, "MinDec <%s>\n", str);
	p = strchr(str, ' '); *p++ = 0;
	return neg * (atof(str) + atof(p)/60.0);
    }
    n = sscanf(str, "%d%*1s %d.%d", &i1, &i2, &i3);
    if (n == 3)
    {
	debug(1, "old gc.com MinDec <%s>\n", str);
	p = strchr(str, ' '); *p++ = 0;
	return neg * (atof(str) + atof(p)/60.0);
    }
    n = sscanf(str, "%d%*2s %d.%d", &i1, &i2, &i3);
    if (n == 3)
    {
	debug(1, "new gc.com MinDec <%s>\n", str);
	p = strchr(str, ' '); *p++ = 0;
	return neg * (atof(str) + atof(p)/60.0);
    }
    n = sscanf(str, "%d %d %lf", &i1, &i2, &f);
    if (n == 3)
    {
	/* DMS */
	debug(1, "DMS <%s>\n", str);
	return neg * (i1 + i2/60.0 + f/3600.0);
    }

    debug(1, "DegDec <%s>\n", str);
    return neg * atof(str);
}

int
main(int argc, char *argv[])
{
    #ifndef __CYGWIN__
	extern int	optind;
	extern char	*optarg;
    #endif
    int		c;

    int		zone;
    char	nz;
    double	lat, lon, x, y;
    char	buf[256];

    while ( (c = getopt(argc, argv, "+enmlzD:?h")) != EOF)
	switch (c)
	{
	case 'e':
	    Easting = 1;
	    break;
	case 'n':
	    Northing = 1;
	    break;
	case 'm':
	    MultiLine = 1;
	    break;
	case 'l':
	    LatBand = 1;
	    break;
	case 'z':
	    Zone = 1;
	    break;
	case 'D':
	    Debug = atoi(optarg);
	    break;
	default:
	    usage();
	    exit(1);
	}

    argc -= optind;
    argv += optind;

    if (argc < 2)
    {
	usage();
	exit(1);
    }

    if (argc == 2)
    {
	lat = getll(argv[0]);
	lon = getll(argv[1]);
    }
    else if (argc == 4)
    {
	/* space separated MinDec */
	snprintf(buf, sizeof(buf), "%s %s", argv[0], argv[1]);
	lat = getll(buf);
	snprintf(buf, sizeof(buf), "%s %s", argv[2], argv[3]);
	lon = getll(buf);
    }
    else if (argc == 6)
    {
	if (strcmp(argv[0], "N") == 0 || strcmp(argv[0], "S") == 0)
	{
	    /* gc.com webpage style MinDec */
	    snprintf(buf, sizeof(buf), "%s%s %s", argv[0], argv[1], argv[2]);
	    lat = getll(buf);
	    snprintf(buf, sizeof(buf), "%s%s %s", argv[3], argv[4], argv[5]);
	    lon = getll(buf);
	}
	else
	{
	    /*DMS */
	    snprintf(buf, sizeof(buf), "%s %s %s", argv[0], argv[1], argv[2]);
	    lat = getll(buf);
	    snprintf(buf, sizeof(buf), "%s %s %s", argv[3], argv[4], argv[5]);
	    lon = getll(buf);
	}
    }
    else
    {
	error(1, "Wierd number of arguments: %d\n", argc);
	exit(1);
    }

    debug(1, "%.6f %.6f\n", lat, lon);

    DegToUTM (lat, lon, &zone, &nz, &x, &y);

    if (y >= 10000000) y -= 10000000;

    if (Easting && Northing)
	printf("%d%s%d\n",
		(int) (x+0.5),
		MultiLine ? "\n" : " ",
		(int) (y+0.5));
    else if (Zone)
	printf("%d\n", zone);
    else if (LatBand)
	printf("%c\n", nz);
    else if (Easting)
	printf("%d\n", (int) (x+0.5));
    else if (Northing)
	printf("%d\n", (int) (y+0.5));
    else
	printf("%d%s%c%s%d%s%d\n",
		zone,
		MultiLine ? "\n" : " ",
		nz,
		MultiLine ? "\n" : " ",
		(int) (x+0.5),
		MultiLine ? "\n" : " ",
		(int) (y+0.5));

    exit(0);
}
