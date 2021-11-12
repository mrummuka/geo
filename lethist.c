#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <ctype.h>

/*
 * Global option flags
 */
int	Debug = 0;
int	Hist[256];

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
"	lethist - Letter histogram\n"
"\n"
"SYNOPSIS\n"
"	lethist [options] [words] ...\n"
"\n"
"DESCRIPTION\n"
"	Letter histogram from <stdin> or from 'words'.\n"
"\n"
"EXAMPLE\n"
"	Letter histogram:\n"
"\n"
"	 $ lethist | sort -k2 -n -r\n"
"	 1 5 - 8 ) ) W 5 - ( + ) ) ; 4 8 W 5 ; 8 ( * + ; 8 ; W + 0 5 ( 3 8 9\n"
"	 ? 0 ; 6 ; ( ? * K 8 ! ; ( 8 8 ) W 6 ; 4 5 1 5 0 0 8 * + * 8 6 * 2 8\n"
"	 ; W 8 8 * ; 4 8 ! 8 5 ; 4 ) 4 8 5 ! 6 ) 6 * ; 4 8 9 6 ! ! 0 8 + 1 ;\n"
"	 4 8 ; + . 0 6 9 2 + 1 ; 4 8 1 5 0 0 8 * ; ( 8 8 3 + ; 4 8 ( 8 1 ( +\n"
"	 9 ; 4 8 ! 8 5 ; 4 ) 4 8 5 ! ) 4 + + ; 5 2 8 8 0 6 * 8 ; 4 6 ( ; : 1\n"
"	 8 8 ; + ? ; ; + ; 4 8 ) + ? ; 4.\n"
"\n"
"	 $ lethist \"Cottonwood trees are, perhaps, the best shade trees\"\n"
"\n"
"OPTIONS\n"
"       -t          Print total\n"
"       -D lvl      Set Debug level [%d]\n"
"\n"
"SEE ALSO\n"
"       addletters(1)\n"
	, Debug
	);

	exit(1);
}

int DoTotal = 0;

int
main(int argc, char *argv[])
{
	#ifndef __CYGWIN__
	    extern int	optind;
	    extern char	*optarg;
	#endif
	int		c, i, j, total;

	while ( (c = getopt(argc, argv, "tD:?h")) != EOF)
		switch (c)
		{
		case 't':
			DoTotal = 1;
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

	if (argc == 0)
	{
	    // Compute histogram
	    while ((c = getchar()) != EOF)
	    {
		if (!isprint(c)) continue;
		if (c == ' ') continue;
		++Hist[c];
	    }
	}
	else
	{
	    for (i = 0; i < argc; ++i)
	    {
		for (j = 0; (c = argv[i][j]); ++j)
		{
		    if (!isprint(c)) continue;
		    if (c == ' ') continue;
		    ++Hist[c];
		}
	    }
	}

	// Print it out
	total = 0;
	for (i = 0; i < 256; ++i)
	{
	    if (Hist[i] == 0) continue;
	    printf("%c	%d\n", i, Hist[i]);
	    total += Hist[i];
	}
	if (DoTotal)
	    printf("TOTAL	%d\n", total);

	exit(0);
}
