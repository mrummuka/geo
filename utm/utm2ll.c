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
int	LatOnly;
int	LonOnly;
int	Fmt = 0;
	#define FMT_DEGDEC	0
	#define	FMT_MINDEC	1
	#define	FMT_RICKDEC	2
	#define	FMT_DMS		3

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
"	utm2ll - Convert Universal Transverse Mercator (UTM) to lat/lon\n"
"SYNOPSIS\n"
"	utm2ll [options] zone [nz] easting northing\n"
"	utm2ll [options] zone_nz E easting N northing\n"
"\n"
"	Convert UTM to WGS-84 DegDec latitude/longitude.\n"
"\n"
"OPTIONS\n"
"       -l          Print latitude only\n"
"       -L          Print longitude only\n"
"       -odegdec    Print lat/lon in DegDec format (default)\n"
"       -omindec    Print lat/lon in MinDec format\n"
"       -orickdec   Print lat/lon in Rick's MinDec format\n"
"       -odms       Print lat/lon in DMS format\n"
"       -D lvl      Set Debug level [%d]\n"
"\n"
"EXAMPLES\n"
"	Convert:\n"
"\n"
"	 $ utm2ll 15 T 460601 4972618\n"
"	 44.905897 -93.499074\n"
"\n"
"	 $ utm2ll 13T E 511168 N 4553536\n"
"	 41.133054 -104.866940\n"
	, Debug
	);

	exit(1);
}

void
outfmt(double coord, char *lets)
{
    char	let = (coord >= 0) ? lets[0] : lets[1];

    switch (Fmt)
    {
    case FMT_DEGDEC:
	printf("%f", coord);
	break;
    case FMT_MINDEC:
	{
	    int		deg = coord;
	    double	min = fabs(coord - deg) * 60.0;
	    printf("%c%d %s%.3f",
		    let, abs(deg), (min < 10) ? "0" : "", min);
	}
	break;
    case FMT_RICKDEC:
	{
	    int		deg = coord;
	    double	min = fabs(coord - deg) * 60.0;
	    printf("%c%d.%s%.3f",
		    let, abs(deg), (min < 10) ? "0" : "", min);
	}
	break;
    case FMT_DMS:
	{
	    int		deg = coord;
	    double	fmin = fabs(coord - deg) * 60.0;
	    int		min = fmin;
	    int		sec = (fmin-min) * 60.0;
	    printf("%d %02d %02d", deg, min, sec);
	}
	break;
    default:
	error(1, "Format not implemented yet\n");
	break;
    }
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
	double		easting;
	double		northing;
	char		nz;
	int		southhemi;
	double		lat, lon;
	int		len;

	while ( (c = getopt(argc, argv, "lLo:D:?h")) != EOF)
		switch (c)
		{
		case 'l':
			LatOnly = 1;
			break;
		case 'L':
			LonOnly = 1;
			break;
		case 'o':
			if (strcmp(optarg, "degdec") == 0)
			    Fmt = FMT_DEGDEC;
			else if (strcmp(optarg, "DegDec") == 0)
			    Fmt = FMT_DEGDEC;
			else if (strcmp(optarg, "MinDec") == 0)
			    Fmt = FMT_MINDEC;
			else if (strcmp(optarg, "mindec") == 0)
			    Fmt = FMT_MINDEC;
			else if (strcmp(optarg, "RickDec") == 0)
			    Fmt = FMT_RICKDEC;
			else if (strcmp(optarg, "rickdec") == 0)
			    Fmt = FMT_RICKDEC;
			else if (strcmp(optarg, "dms") == 0)
			    Fmt = FMT_DMS;
			else if (strcmp(optarg, "DMS") == 0)
			    Fmt = FMT_DMS;
			else
			    error(1, "Unknown output format '%s'\n", optarg);
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

	if (argc < 3)
	    usage();

	zone = atoi(argv[0]);
	if (argc == 5)
	{
	    nz = 0;
	    len = strlen(argv[0]);
	    if (len >= 1)
		nz = argv[0][len-1];
	    else
		error(1, "UTM format not right, nx = 0!\n");
	    if (strcmp(argv[1], "E"))
		error(1, "UTM format not right, 'E' isn't there!\n");
	    easting = atof(argv[2]);
	    if (strcmp(argv[3], "N"))
		error(1, "UTM format not right, 'N' isn't there!\n");
	    northing = atof(argv[4]);
	}
	else if (argc > 3)
	{
	    nz = argv[1][0];
	    easting = atof(argv[2]);
	    northing = atof(argv[3]);
	}
	else
	{
	    nz = 'T';
	    easting = atof(argv[1]);
	    northing = atof(argv[2]);
	}

	southhemi = 0;
	if (nz >= 'A' && nz < 'N')
	    southhemi = 1;
	else if (nz >= 'a' && nz < 'n')
	    southhemi = 1;

	UTMtoDeg (zone, southhemi, easting, northing, &lat, &lon);

	if (!LatOnly && !LonOnly)
	{
	    outfmt(lat, "ns");
	    printf(" ");
	    outfmt(lon, "ew");
	    printf("\n");
	}
	else
	{
	    if (LatOnly)
	    {
		outfmt(lat, "ns");
		printf("\n");
	    }
	    if (LonOnly)
	    {
		outfmt(lon, "ew");
		printf("\n");
	    }
	}

	exit(0);
}
