/*
 * Donated to the public domain.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <regex.h>
#include <assert.h>
#include <unistd.h>

#ifdef REG_BASIC
	#define regcompiled(rep) (rep)->re_g
#else
#ifdef __REPB_PREFIX
	#define regcompiled(rep) (rep)->__buffer
#else
	#define regcompiled(rep) (rep)->buffer
#endif
#endif

/*
 * Global option flags
 */
int	Debug = 0;
int	Mixed = 1;
int	ListCat = 0;
int	RectOnly = 0;
int	Delete = 0;
int	MinDec = 0;
int	Format = 0;
regex_t	CategoryRE;
regex_t	NameRE;
char	*Category;

int	RecNum = 0;

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

	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);

	if (fatal > 0)
	    exit(fatal);
	else
	    return fatal;
}

void
usage(void)
{
	fprintf(stderr,
"NAME\n"
"	pgpdb2txt - Convert a Mapopolis Place Guide .pdb file to text\n"
"\n"
"SYNOPSIS\n"
"	pgpdb2txt [options] [file] ...\n"
"\n"
"DESCRIPTION\n"
"	Convert a Mapopolis Platinum Place Guide .pdb file to text.\n"
"	This is useful for creating a waypoint database for GpsDrive.\n"
"\n"
"	The -F0 (default) output text format is:\n"
"\n"
"	    Category|Name|StreetAddress|CityStateZip|Phone|Lat|Lon|\n"
"\n"
"	The -F1 or -F2 output format is:\n"
"\n"
"	    Category|Name|StreetAddress|CityStateZip|Phone|Lat|Lon|Index|\n"
"\n"
"	The -F3 (GpsDrive way.txt) output format is:\n"
"\n"
"	    ShortName Lat Lon Category\n"
"\n"
"	The -F4 (GpsDrive SQL) output format is:\n"
"\n"
"	    ShortName Lat Lon Category Comment\n"
"\n"
"OPTIONS\n"
"       -c category  Select category [*]\n"
"                    category may be an RE, e.g. -cRest.*\n"
"       -n name      Select name [*]\n"
"                    name may be an RE, e.g. -n.*McDonald.*\n"
"       -l           Just list the categories in this file.\n"
"       -o dec       Output lat/lat in 'degdec' (44.456789)\n"
"                    or 'mindec' (44.12.123) format.\n"
"       -r           Just print the lat/lon coverage rectangle of this file.\n"
"       -t type      The waypoint type to output [<category-in-pdb-file>]\n"
"       -u           Do not convert text to mixed case\n"
"       -F1          Append record number as Index\n"
"       -F2          Append filename and record number as Index\n"
"       -F3          Produce output compatible with GpsDrive v1.32 way.txt\n"
"       -F4          Produce output compatible with GpsDrive v1.32 SQL\n"
"       -d           For -F4, just delete selected records\n"
"       -D lvl       Set Debug level [%d]\n"
	, Debug
	);

	exit(1);
}

typedef struct pdb_header
{       /* 78 bytes total */
	char	name[31+1];
	short	attributes;
	short	version;
	int	create_time;
	int	modify_time;
	int	backup_time;
	int	modificationNumber;
	int	appInfoID;
	int	sortInfoID;
	char	type[4];
	char	creator[4];
	int	id_seed;
	int	nextRecordList;
	short	numRecords;
} __attribute__((packed)) PDBHDR;

typedef struct pdb_rec
{   /* 8 bytes total	*/
	int	offset;
	char	attributes;
	char	uniqueID[3];
} PDBREC;

#define	UNLIMITED	999999999	// Well, not really :-)

static inline void
beswap16(short *sp)
{
    char	*p = (char *) sp;
    char	tmp;
    const short	num = 0x1122;

    if (((char *)&num)[0] == 0x22)
    {
	tmp = p[0];
	p[0] = p[1];
	p[1] = tmp;
    }
}

static inline void
beswap32(int *sp)
{
    char	*p = (char *) sp;
    char	tmp;
    const long	num = 0x11223344;

    if (((char *)&num)[0] == 0x44)
    {
	tmp = p[0];
	p[0] = p[3];
	p[3] = tmp;
	tmp = p[1];
	p[1] = p[2];
	p[2] = tmp;
    }
}

/*
 * Substitute a string
 */
char *
strsub(char *d, int dlen, char *s, char *search, char *replace)
{
    char	*p;
    int	len = strlen(s);
    int	slen = strlen(search);
    int	rlen = strlen(replace);

    // Insure we have room
    if ( (len+rlen-slen) >= (dlen-1))
    {
	strncpy(d, s, dlen-1);
	d[dlen-1] = 0;
	return NULL;
    }

    // Find search string
    p = strstr(s, search);
    if (!slen || !p)
    {
	strncpy(d, s, dlen-1);
	d[dlen-1] = 0;
	return NULL;
    }

    // copy first part
    len = p - s;
    memcpy(d, s, len); d[len] = 0;

    // copy replacement
    strcat(d, replace);

    // copy last part
    strcat(d, p+slen);
    return (d+len);
}

/*
 * Find the *last* occurance of a needle in a haystack
 */
char *
strrstr(const char *haystack, const char *needle)
{
    char	*p;
    int		nlen = strlen(needle);

    if (strlen(haystack) < nlen)
	return NULL;
    for (p = strchr(haystack, 0) - nlen; p > haystack; --p)
    {
	if (memcmp(p, needle, nlen) == 0)
	    return (p);
    }
    return NULL;
}

/*
 * Delete characters from a set
 */
char *
strkill(char *str, char *kill, int nonascii)
{
    char	*sp, *dp;

    for (dp = sp = str; *sp; ++sp)
    {
	if (nonascii && !isascii(*sp))
	    continue;
	if (strchr(kill, *sp) == 0)
	    *dp++ = *sp;
    }
    *dp = 0;
    return str;
}

/*
 * Delete a single character in a string
 */
static inline void
strdel(char *str)
{
    if (*str)
    {
	char *p;
	for (p = str+1; *p; ++p)
	    *str++ = *p;
	*str = 0;
    }
}

/*
 * Split a string
 */
int
strsplit(char **strary, int nary, char *str, char sep)
{
    int		i;
    char	*p;

    for (i = 0; i < nary; ++i)
    {
	strary[i] = str;
	p = strchr(str, sep);
	if (!p)
	    return i+1;
	*p = 0;
	str = p+1;
    }
    return i;
}

/*
 * Capitalize a string
 */
void
strcap(unsigned char *str)
{
    int			state = 0;
    unsigned char	c;

    while ((c = *str))
    {
	switch (state)
	{
	case 0:
	    if (c == ' ' || c == '	')
		break;
	    if (isalpha(c))
	    {
		*str = toupper(c);
		if (isalpha(str[1]) && str[2] == ' ' && isdigit(str[3])
			 && isdigit(str[4]) && isdigit(str[5])
			 && isdigit(str[6]) && isdigit(str[7])
			 && !isdigit(str[8]))
		    {} // State abreviation
		else if (*str == 'M' && tolower(str[1]) == 'c')
		{
		    // McSomething
		    ++str;
		    *str = tolower(*str);
		}
		else
		    state = 1;
	    }
	    else
		state = 1;
	    break;
	case 1:
	    if (c == ' ' || c == '	')
		state = 0;
	    if (isupper(c))
		*str = tolower(c);
	    break;
	}
	++str;
    }
}

/*
 * Shorten a string
 */
char *
strshorten(const char *istring, int target_len, char *killset)
{
    char	*ostring;
    char	*p;
    char	*np;

    // Get rid of leading "The" or "the"
    if (strncmp(istring, "The ", 4) == 0)
	istring += 4;
    else if (strncmp(istring, "the ", 4) == 0)
	istring += 4;

    ostring = strdup(istring);

    // Get rid of " by BLAH" at end of string
    if ((p = strrstr(ostring, " by ")))
	    *p = 0;

    // Get rid of any characers in the killset
    strkill(ostring, killset, 1);

    /*
     * Toss vowels to approach target length, but don't toss them 	
     * if we don't have to.  We always keep the leading two letters
     * to preserve leading vowels and some semblance of pronouncability.
     */
    p = strchr(ostring, 0);
    if ((p-ostring) > 2)
    {
	char	*sp = ostring + 2;
	char	vowels[] = "aeiouAEIOU";

	for (--p; p >= sp; --p)
	{
	    // printf("Moe <%s>\n", ostring);
	    if (strlen(ostring) <= target_len)
		return ostring;
	    if (strchr(vowels, *p))
		strdel(p);
	}
    }
    
    /*
     * Next to last thing, we look for trailing numbers and try to 
     * preserve those.  This ensures that.
     * Walk in the Woods 1.
     * Walk in the Woods 2.
     */
    np = ostring + strlen(ostring);
    while (isdigit((unsigned char) *(np-1) ))
	np--;
    //if (np)
	//nlen = strlen(np);

    /*
     * Now brutally truncate the resulting string, preserve trailing 
     * numeric data.
     */
    if ((strlen(ostring)) > target_len)
	strcpy(ostring + target_len - strlen(np), np);

    return ostring;
}

/*
 * copy "num" bytes from FILE into buf.
 * If "num" is negative, copy up to and including a NUL byte
 */
int
copybytes(FILE *fp, char *buf, int bufsize, int num)
{
    int	rc;
    int	i;
    int	left = num;

    i = 0;
    while (left--)
    {
	rc = fgetc(fp);
	if (rc == EOF)
	    return (EOF);

	if (buf && i < bufsize)
	    buf[i] = rc;
	++i;
	if (num < 0 && rc == 0)
	    return (i);
    }
    return (i);
}

/*
 * Format of Record 0 in the PDB file, so far as we know.
 */
typedef struct record0
{
	char	unk[6];
	int	lon1;
	int	lat1;
	int	lon2;
	int	lat2;
	int	lonD;
	int	latD;
	char	name[31+1];
	char	unk2[35];
	char	demo;
	char	unk3[4];
	unsigned int	expcode;
	// ... more stuff ...
} __attribute__((packed)) REC0;

double	Lat1, Lon1;
double	Lat2, Lon2;
double	LatD, LonD;
int	Demo;

#define	LONDIV	(85116.044444)
#define	LATDIV	(1000000.0/9)
#define	LONDIV2	(85116.044444/2)
#define	LATDIV2	(1000000.0/(9*2))

/*
 * Convert record 0
 */
int
convert_rec0(FILE *fp, char *name, int recno, int recsize)
{
	int	rc;
	REC0	rec0;

	rc = copybytes(fp, (char *) &rec0, sizeof(rec0), recsize);
	if (rc == EOF)
		return error(-1, "Short record %d in file '%s'\n", recno, name);

	beswap32(&rec0.lon1); Lon1 = rec0.lon1 / LONDIV;
	beswap32(&rec0.lat1); Lat1 = rec0.lat1 / LATDIV;
	beswap32(&rec0.lon2); Lon2 = rec0.lon2 / LONDIV;
	beswap32(&rec0.lat2); Lat2 = rec0.lat2 / LATDIV;
	beswap32(&rec0.lonD); LonD = rec0.lonD / LONDIV2;
	beswap32(&rec0.latD); LatD = rec0.latD / LATDIV2;

	if (RectOnly)
	{
	    printf("%s	%.5f	%.5f	%.5f	%.5f\n",
		    fp == stdin ? rec0.name : name,
			Lat1, Lon1,
			Lat2, Lon2);
	    return 1;
	}

	debug(1, "%s: %.5f %.5f %.5f %.5f %.5f %.5f\n",
			rec0.name,
			Lat1, Lon1,
			Lat2, Lon2,
			LatD, LonD);

	beswap32((int *) &rec0.expcode);
	debug(2, "%s: %s (%08x, %lu)\n",
			rec0.name,
			rec0.demo ? "Demo" : "Paid",
			rec0.expcode, rec0.expcode);

	Demo = rec0.demo;
	if (Demo)
		debug(0, "Demo data: Please purchase paid data"
			" to access all records.\n");

	return 0;
}

/*
 * Decode the information field
 */
void
decode(char *buf)
{
    int	i;

    for (i = 0; buf[i]; ++i)
	buf[i] = buf[i] ^ ((i%96) & 0xf);
}

/*
 * Convert a record to text
 */
int
convert_rec(FILE *ofp, FILE *fp, char *name, int recno, int recsize)
{
    int		rc;
    char	namebuf[512];
    char	fieldbuf[512];
    char	infobuf[512];
    char	*shortname;
    char	*infop;
    int		entryno;
    char	*err;
    int		lastrec = recsize == UNLIMITED;
    char	*field[10];
    char	*p;

    debug(2, "Record %d, size %d\n", recno, recsize);
    ++RecNum;

    if (recno == 0)
    {
	// Record we don't care about 
	return convert_rec0(fp, name, recno, recsize);
    }

    // Skip initial 10 byte header.  No idea what it means
    rc = copybytes(fp, NULL, 0, 10);
    if (rc == EOF)
	return error(-1, "Short hdr in %s#%d\n", name, recno);
    recsize -= 10;

    entryno = 0;
    while (recsize > 0)
    {
	typedef struct
	{
	    unsigned short unk1, unk2;
	    unsigned short lon1d, lat1d;
	    unsigned short lon2d, lat2d;
	} __attribute__((packed)) ENTHDR;

	ENTHDR	enthdr;
	double	lat, lon;
	char	slat[12], slon[12];

	++entryno;

	// Copy 12 byte entry header.
	rc = copybytes(fp, (char *) &enthdr, sizeof(enthdr), 12);
	if (rc == EOF && lastrec)
	    break;
	if (rc == EOF)
	{
	    err = "Short 12";
	error:
	    return error(-1, "%s in %s#%d:%d\n", err, name, recno, entryno);
	}
	recsize -= 12;

	beswap16((short *) &enthdr.unk1);
	beswap16((short *) &enthdr.unk2);
	beswap16((short *) &enthdr.lon1d);
	beswap16((short *) &enthdr.lat1d);
	beswap16((short *) &enthdr.lon2d);
	beswap16((short *) &enthdr.lat2d);

	lat = Lat1 + enthdr.lat1d/LATDIV2;
	lon = Lon1 + enthdr.lon1d/LONDIV2;
	switch (MinDec)
	{
	case 0:
	default:
	    sprintf(slat, "%.6f", lat);
	    sprintf(slon, "%.6f", lon);
	    break;
	case 1:
	    {
		int	dd;
		double  mm;

		dd = lat; mm = 60 * (lat - dd); if (mm < 0) mm = -mm;
		sprintf(slat, "%d.%.3f", dd, mm);
		dd = lon; mm = 60 * (lon - dd); if (mm < 0) mm = -mm;
		sprintf(slon, "%d.%.3f", dd, mm);
	    }
	    break;
	}

	// Copy the cleartext name.  Its NUL terminated.
	rc = copybytes(fp, namebuf, sizeof(namebuf), -1);
	if (rc == EOF)
	{
	    err = "Short name";
	    goto error;
	}
	recsize -= rc;

	// Skip 6 more bytes that we don't understand
	rc = copybytes(fp, NULL, 0, 6);
	if (rc == EOF)
	{
	    err = "Short 6";
	    goto error;
	}
	recsize -= 6;

	// Copy the information buffer.  Its NUL terminated
	rc = copybytes(fp, infobuf, sizeof(infobuf), -1);
	if (rc == EOF)
	{
	    err = "Short info";
	    goto error;
	}
	recsize -= rc;

	// Decode the information buffer into ASCII
	infobuf[sizeof(infobuf)-1] = 0;
	infop = infobuf;
	while (*infop == 0x40)
	    ++infop;	// skip more unknown stuff
	decode(infop);

	// Fix spelling mistakes
	strsub(fieldbuf, sizeof(fieldbuf), namebuf,
			"RELIGOUS|", "RELIGIOUS|");

	// append the info buffer 
	p = strchr(fieldbuf, 0);
	*p++ = '|';
	strcpy(p, infop);

	memset(field, 0, sizeof(field));
	rc = strsplit(field, sizeof(field)/sizeof(field[0]),
		    fieldbuf+1, '|');
	// Field[0] Category
	// Field[1] Name
	// Field[2] Street
	// Field[3] CSZ
	// Field[4] Phone
	if (Mixed)
	{
	    int	i;

	    for (i = 0; i < rc; ++i)
		strcap((unsigned char *) field[i]);
	}

	// Print the record
	if (ListCat)
	{
	    fprintf(ofp, "%s\n", field[0]);
	}
	else
	{
	    if (Demo && recno & 1)
	    {
		    // TODO: Figure out how to decode expiration
		    // time and implement that instead of this.
		    continue;
	    }

	    if (regcompiled(&CategoryRE))
	    {
		rc = regexec(&CategoryRE, field[1], 0, NULL, 0);
		if (rc) continue;
	    }
	    if (regcompiled(&NameRE))
	    {
		rc = regexec(&NameRE, field[1], 0, NULL, 0);
		if (rc) continue;
	    }

	    switch (Format)
	    {
	    case 0:
		fprintf(ofp, "%s|%s|%s|%s|%s|%s|%s|\n",
		    Category ? Category : field[0],
		    field[1], field[2], field[3], field[4], slat, slon);
		break;
	    case 1:
		fprintf(ofp, "%s|%s|%s|%s|%s|%s|%s|%d|\n",
		    Category ? Category : field[0],
		    field[1], field[2], field[3], field[4], slat, slon,
		    RecNum);
		break;
	    case 2:
		fprintf(ofp, "%s|%s|%s|%s|%s|%s|%s|%d|%s|\n",
		    Category ? Category : field[0],
		    field[1], field[2], field[3], field[4], slat, slon,
		    RecNum, name);
		break;
	    case 3:
		// Create short name.
		strcpy(namebuf, field[1]);
		shortname = strshorten(namebuf, 20, " '");

		// strcpy(namebuf, field[1]);
		// infop = strshorten(namebuf, 20, " ");
		// strcpy(namebuf, infop);
		// free(infop);
		// strcat(namebuf, "-");
		// strcat(namebuf, field[4]);

		// Get rid of blanks in category
		strkill(Category ? Category : field[0], " ", 1);

		fprintf(ofp, "%s %s %s %s\n",
		    shortname, slat, slon, Category ? Category : field[0]);
		free(shortname);
		break;
	    case 4:
		// Create short name.
		strkill(field[1], " '", 1);
		strcpy(namebuf, field[1]);
		shortname = strshorten(namebuf, 20, " '");

		// Get rid of blanks in category
		strkill(Category ? Category : field[0], " '", 1);
		// Get rid of quotes in other fields
		strkill(field[2], " '", 1);
		strkill(field[3], " '", 1);
		strkill(field[4], " '", 1);

		fprintf(ofp,"delete from waypoints where"
			    "  name='%s' and type='%s'"
			    "  and lat='%.5f' and lon='%.5f';\n",
			    shortname,
			    Category ? Category : field[0], lat, lon);
		if (!Delete)
		    fprintf(ofp,
			    "insert into waypoints (name,lat,lon,type,comment)"
			    "  values('%s', '%.5f', '%.5f', '%s',"
			    " '%s, %s, %s, %s');\n",
			    shortname, lat, lon,
			    Category ? Category : field[0],
			    field[1], field[2], field[3], field[4]);
		free(shortname);
		break;
	    }
	}
    }
    return (0);
}

int
convert(FILE *ofp, FILE *fp, char *name)
{
	PDBHDR	pdbhdr;
	int	len;
	PDBREC	*pdbrec;
	long	fileoff;
	int	i;
	int	rc;

	len = fread(&pdbhdr, sizeof(pdbhdr), 1, fp);
	if (len != 1)
	{
		fprintf(stderr, "Missing PDB header in file '%s'\n", name);
		return -1;
	}
	fileoff = sizeof(pdbhdr);

	beswap16(&pdbhdr.numRecords);

	pdbrec = malloc(pdbhdr.numRecords * sizeof(*pdbrec));
	if (!pdbrec)
	{
		fprintf(stderr, "Can't get space for records in file '%s'\n",
				name);
		return -2;
	}

	len = fread(pdbrec, sizeof(*pdbrec), pdbhdr.numRecords, fp);
	if (len != pdbhdr.numRecords)
	{
		fprintf(stderr, "Missing PDB records in file '%s'\n", name);
		free(pdbrec);
		return -3;
	}
	fileoff += sizeof(*pdbrec) * pdbhdr.numRecords;

	beswap32(&pdbrec[0].offset);
	for (i = 0; i < pdbhdr.numRecords; ++i)
	{
		int	size;

		// Skip bytes til we get to this record
		while (fileoff != pdbrec[i].offset)
		{
			if (fgetc(fp) == EOF)
			{
				fprintf(stderr, "Short record #%d in '%s'\n",
					i, name);
				free(pdbrec);
				return (-4);
			}
			++fileoff;
		}

		if (fp != stdin)
		{
			long	here = ftell(fp);

			if (here != fileoff)
			{
				fprintf(stderr, "At %ld, should be %ld\n",
					here, fileoff);
				return(-5);
			}
		}

		// Figure out the size of this record.  If its the
		// last record, we don't know til we hit EOF
		if (i == (pdbhdr.numRecords - 1))
			size = UNLIMITED;
		else
		{
			beswap32(&pdbrec[i+1].offset);
			size = pdbrec[i+1].offset - pdbrec[i].offset;
		}

		// Convert a single record
		rc = convert_rec(ofp, fp, name, i, size);
		if (rc == 0)
			fileoff += size;
		else
		{
			free(pdbrec);
			return rc;
		}
	}

	free(pdbrec);
	return (0);
}

int
main(int argc, char *argv[])
{
    #ifndef __CYGWIN__
	extern int	optind;
	extern char	*optarg;
    #endif
    int		c;
    int		rc;
    FILE	*ofp;
    char	filter[512];

    assert(sizeof(PDBHDR) == 78);
    assert(sizeof(PDBREC) == 8);

    while ( (c = getopt(argc, argv, "c:dn:lo:rt:F:SD:?h")) != EOF)
	switch (c)
	{
	case 'c':
	    if (strcmp(optarg, "*") && strcmp(optarg, ".*"))
	    {
		rc = regcomp(&CategoryRE, optarg, REG_ICASE|REG_NOSUB);
		if (rc)
		    error(1, "Illegal RE '%s'\n", optarg);
	    }
	    break;
	case 'n':
	    if (strcmp(optarg, "*") && strcmp(optarg, ".*"))
	    {
		rc = regcomp(&NameRE, optarg, REG_ICASE | REG_NOSUB);
		if (rc)
		    error(1, "Illegal RE '%s'\n", optarg);
	    }
	    break;
	case 'd':
	    Delete = 1;
	    break;
	case 'l':
	    ListCat = 1;
	    RectOnly = 0;
	    break;
	case 'o':
	    if (strcmp(optarg, "mindec") == 0)
		MinDec = 1;
	    else if (strcmp(optarg, "degdec") == 0)
		MinDec = 0;
	    else
		error(1, "Only -omindec or -odegdec allowed.\n");
	    break;
	case 'r':
	    RectOnly = 1;
	    ListCat = 0;
	    break;
	case 't':
	    if (optarg[0])
		Category = optarg;
	    break;
	case 'F':
	    Format = atoi(optarg);
	    break;
	case 'S':
	    Format = 4;
	    break;
	case 'u':
	    Mixed = 0;
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

    filter[0] = 0;
    if (ListCat)
	strcat(filter, "sort -u");

    if (filter[0])
    {
	ofp = popen(filter, "w");
	if (!ofp)
	    error(2, "Can't run filter '%s'\n", filter);
    }
    else
	ofp = stdout;

    if (argc == 0)
	convert(ofp, stdin, "*stdin*");
    else
    {
	FILE	*fp;
	int	i;

	for (i = 0; i < argc; ++i)
	{
	    fp = fopen(argv[i], "r");
	    if (!fp)
		    error(1, "Can't open '%s'\n", argv[i]);
	    rc = convert(ofp, fp, argv[i]);
	    fclose(fp);
	    if (rc != 0)
		break;
	}
    }

    if (filter[0])
	pclose(ofp);

    exit(0);
}
