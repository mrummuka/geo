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
long long	Total = 0;
int	Reverse = 0;
int	SingleChar = 0;
int	Length = 0;
int	ConsVowels = 0;
int	SometimesY = 0;
int	Aequals1 = 1;
int	DigitalRoot = 0;
int	Binary = 0;
int	Kay = 0;
int	Phone = 0;

char	Vals[26];
char	ValsRev[26];
char	ValsScrabble[26] =
{
    1, 3, 3, 2, 1, 4, 2, 4, 1, 8, 5, 1, 3,
    1, 1, 3, 10, 1, 1, 1, 1, 4, 4, 8, 4, 10
};
char	ValsDigitalRoot[26] =
{
    1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4,
    5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8
};
char	ValsDigitalRoot0[26] =
{
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3,
    4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7
};
char	ValsScrabbleTiles[26] =
{
    9, 2, 2, 4, 12, 2, 3, 2, 9, 1, 1, 4, 2,
    6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1
};
char	ValsScrabbleDe[26] =
{
    1, 3, 4, 1, 1, 4, 2, 2, 1, 6, 4, 2, 3,
    1, 2, 4, 10, 1, 1, 1, 1, 6, 3, 8, 10, 3
};
char	ValsPhoneKeys[26] =
{
    2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6,
    6, 6, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9
};
char	ValsOldPhone[26] =	// q=1 z=0
{
    2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6,
    6, 6, 7, 1, 7, 7, 8, 8, 8, 9, 9, 9, 0
};
char	ValsKayCipher[26] =
{
    27, 28, 29, 30, 31, 32, 33, 34, 35, 0, 10, 11, 12,
    13, 14, 15, 16, 17, 18, 19, 0, 20, 21, 22, 23, 24
};
char	ValsWordsWithFriends[26] =
{
    1, 4, 4, 2, 1, 4, 3, 3, 1, 10, 5, 2, 4,
    2, 1, 4, 10, 1, 1, 1, 2, 5, 4, 8, 3, 10
};
char	ValsQwerty[26] =
{
//  a  b  c  d  e  f  g  h  i  j  k  l  m
    1, 5, 3, 3, 3, 4, 5, 6, 8, 7, 8, 9, 7,
//  n  o  p  q  r  s  t  u  v  w  x  y  z
    6, 9, 0, 1, 4, 2, 5, 7, 4, 2, 2, 6, 1
};
char	ValsAZ[26] =		"abcdefghijklmnopqrstuvwxyz";
char	ValsZA[26] =		"zyxwvutsrqponmlkjihgfedcba";
char	ValsLZAK[26] =		"lmnopqrstuvwxyzabcdefghijk";
char	ValsLAZM[26] =		"lkjihgfedcbazyxwvutsrqponm";
char	ValsFreqLino[26] =	"etaoinshrdlucmfwypvbgkqjxz";
char	ValsFreqMorse[26] =	"eitsanhurdmwgvlfbkopjxczyq";

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
"	addletters - Tool for diddling with letters\n"
"\n"
"SYNOPSIS\n"
"	addletters [options] text ...\n"
"\n"
"DESCRIPTION\n"
"	Tool for diddling with letters.\n"
"\n"
"OPTIONS\n"
"	-a		Use ASCII value of each letter (instead of 1-26)\n"
"	-b		Print in binary\n"
"	-B base		For -r -a, print the value from base N (N=2..36)\n"
"	-d		Use delta between letters\n"
"	-l		Output length\n"
"	-L		Output length of Consonants/Vowels\n"
"	-m		Multiply them together\n"
"	-M modulus	Modulus to use\n"
"	-n		Just print out the numerical value of each letter\n"
"	-N		Shift the numbers: !==1, @==2, #==3, ... )==0\n"
"	-p		When -r, val = val / position\n"
"	-P		Use phone key value of each letter (instead of 1-26)\n"
"	-r		Reverse: e.g. addletters 18 05 22 05 18 19 05\n"
"	-R		Digital Root of letter (e.g. 12=3)\n"
"	-s		Single char: rickrich == 18\n"
"	-G		German Scrabble weights, add *<n> bonus; i.e. start*2\n"
"	-S		Scrabble weights, add *<n> bonus; i.e. start*2\n"
"	-T		Scrabble tiles\n"
"	-t total	Output additional amount to add to get 'total'\n"
"	-v vals		vals is:\n"
"		a-z	A=1, B=2, ... Z=26\n"
"		z-a	A=26, B=25, ... Z=1\n"
"		kay	Kay (Francis Bacon) cipher.\n"
"		l-za-k	A=16, B=17, ... K=26, L=1, M=2, ... Z=15\n"
"		l-az-m	A=12, B=11, ... L=1, M=26, N=25, ... Z=13\n"
"		lino	Linotype machine frequency of letters.\n"
"		morse	Morse code frequency of letters.\n"
"		oldphone	Use old phone keys, q=1 z=0\n"
"		qwerty	Keyboard qaz=1, wsx=2, ... p=0\n"
"		aeiouy	Output length of Consonants/Vowels with Y as a vowel\n"
"	-u		Swedish umlauts åäö instead of german umlauts äöüß\n"
"	-w		Print single words\n"
"	-W		Words With Friends points\n"
"	-x		Print in hex, not decimal\n"
"	-0		A=0, B=1, Z=25\n"
"	-z		A=26, B=25, Z=1\n"
"	-D lvl		Set Debug level [%d]\n"
"EXAMPLE\n"
"	Add the letters in 'geocaching':\n"
"\n"
"	    $ addletters geocaching\n"
"	    72\n"
"\n"
"	Add reverse values by position:\n"
"\n"
"	    $ addletters -r -p 20 30 18 36 70 24 140 64 81 190 33 12 39 112 75\n"
"	    TOFINDTHISCACHE\n"
"\n"
"	Add German umlauts:\n"
"\n"
"	    $ addletters -n ä ö ü ß\n"
"	    27 28 29 30 = 114\n"
"\n"
"SEE ALSO\n"
"       lethist(1)\n"
	, Debug
	);

	exit(1);
}

void
makevals(char *vals)
{
    int i, c;

    memcpy(ValsRev, vals, 26);
    for (i = 0; i <= 25; ++i)
    {
	c = vals[i] - 'a';
	Vals[c] = i;
    }
}

void
to_binary(int n)
{
    int remainder;
    if (n != 0)
    {
	remainder = n % 2;
	to_binary(n/2);
	printf("%d", remainder);
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
    long long	sum;
    long long   sumVowels;
    long long   sumConsolents;
    int		i;
    unsigned char	*p;
    int		mul = 0;
    int		num = 0;
    int		ascii = 0;
    int		base = 10;
    char	*numfmt = "%02lld";
    int		delta = 0;
    int		lastval;
    int		modulus = 0;
    int		words = 0;
    int		scrabble = 0;
    int		position = 0;
    int		shiftnumbers = 0;
    int		za = 0;
    int		unicode = 0;
    int		swedish = 0;

    makevals(ValsAZ);

    while ( (c = getopt(argc, argv,
			    "abB:dlLxmM:nNpPrRsSGt:Tuv:wWz0D:?h")) != EOF)
	    switch (c)
	    {
	    case 'a':
		    ascii = 1;
		    break;
	    case 'b':
		    Binary = 1;
		    break;
	    case 'd':
		    delta = 1;
		    break;
	    case 'l':
		    Length = 1;
		    break;
	    case 'L':
		    ConsVowels = 1;
		    break;
	    case 'm':
		    mul = 1;
		    break;
	    case 'M':
		    modulus = atoi(optarg);
		    if (modulus <= 10)
			numfmt = "%lld";
		    break;
	    case 'n':
		    num = 1;
		    break;
	    case 'N':
		    shiftnumbers = 1;
		    numfmt = "%lld";
		    break;
	    case 'p':
		    position = 1;
		    break;
	    case 'P':
		    for (i = 0; i < 26; ++i)
			Vals[i] = ValsPhoneKeys[i] - 1;
		    Phone = 1;
		    numfmt = "%lld";
		    break;
	    case 'r':
		    Reverse = 1;
		    break;
	    case 'R':
		    DigitalRoot = 1;
		    numfmt = "%lld";
		    break;
	    case 's':
		    SingleChar = 1;
		    break;
	    case 'S':
		    scrabble = 1;
		    for (i = 0; i < 26; ++i)
			Vals[i] = ValsScrabble[i] - 1;
		    break;
	    case 'G':
		    scrabble = 1;
		    for (i = 0; i < 26; ++i)
			Vals[i] = ValsScrabbleDe[i] - 1;
		    break;
	    case 't':
		    Total = atoi(optarg);
		    break;
	    case 'T':
		    scrabble = 1;
		    for (i = 0; i < 26; ++i)
			Vals[i] = ValsScrabbleTiles[i] - 1;
		    break;
	    case 'W':
		    for (i = 0; i < 26; ++i)
			Vals[i] = ValsWordsWithFriends[i] - 1;
		    break;
	    case 'u':
		    swedish = 1;
		    break;
	    case 'v':
		    if (0) ;
		    else if (strcmp("a-z", optarg) == 0)
			makevals(ValsAZ);
		    else if (strcmp("z-a", optarg) == 0)
			makevals(ValsZA);
		    else if (strcmp("lino", optarg) == 0)
			makevals(ValsFreqLino);
		    else if (strcmp("morse", optarg) == 0)
			makevals(ValsFreqMorse);
		    else if (strcmp("l-za-k", optarg) == 0)
			makevals(ValsLZAK);
		    else if (strcmp("l-az-m", optarg) == 0)
			makevals(ValsLAZM);
		    else if (strcmp("aeiouy", optarg) == 0)
		    {
			SometimesY = 1;
			ConsVowels = 1;
		    }
		    else if (strcmp("qwerty", optarg) == 0)
		    {
			for (i = 0; i < 26; ++i)
			    Vals[i] = ValsQwerty[i] - 1;
			numfmt = "%lld";
		    }
		    else if (strcmp("oldphone", optarg) == 0)
		    {
			Phone = 1;
			for (i = 0; i < 26; ++i)
			    Vals[i] = ValsOldPhone[i] - 1;
			numfmt = "%lld";
		    }
		    else if (strcmp("kay", optarg) == 0)
		    {
			Kay = 1;
			for (i = 0; i < 26; ++i)
			    Vals[i] = ValsKayCipher[i] - 1;
		    }
		    else
			error(1, "vals is not 'a-z', 'z-a', "
			    "'lino', 'morse', 'qwerty', or 'oldphone'!\n");
		    break;
	    case 'w':
		    words = 1;
		    break;
	    case 'z':
		    za = 1;
		    makevals(ValsZA);
		    break;
	    case '0':
		    Aequals1 = 0;
		    break;
	    case 'B':
		    base = atoi(optarg);
		    if (base < 2 || base > 36)
			error(1, "base is not between 2 and 36!\n");
		    break;
	    case 'x':
		    numfmt = "%02llx";
		    base = 16;
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

    if (DigitalRoot)
    {
	if (za)
	    for (i = 0; i < 26; ++i)
		Vals[i] = ValsZA[i] - 'a';
	else
	    for (i = 0; i < 26; ++i)
		Vals[i] = Aequals1 ? ValsDigitalRoot[i] - 1
				: ValsDigitalRoot0[i];
    }

    if (argc == 0)
    {
	if (Reverse)
	{
	    for (c = 0; c <= 25; ++c)
		printf("%02d ", c + Aequals1);
	    printf("\n");
	    for (c = 0; c <= 25; ++c)
		printf("%c  ", toupper((unsigned char) ValsRev[c]));
	    printf("\n");
	}
	else
	{
	    for (c = 'A'; c <= 'Z'; ++c)
		printf("%2c ", c);
	    printf("\n");
	    for (c = 'A'; c <= 'Z'; ++c)
	    {
		i = Vals[tolower(c) - 'a'] + Aequals1;
		if (modulus != 0) i %= modulus;
		printf("%2d ", i);
	    }
	    printf("\n");
	}
	exit(0);
    }

    if (Reverse)
    {
	for (i = 0; i < argc; ++i)
	{
	    int val, valbase;
	    val = atoi(argv[i]) - Aequals1;
	    valbase = (int) strtol(argv[i], NULL, base) - Aequals1;
	    if (position)
	    {
		val = val / (i+1);
		printf("%c", toupper((unsigned char) ValsRev[val]));
	    }
	    else if (ascii)
		printf("%c", (int) strtol(argv[i], NULL, base) );
	    else if (Kay)
	    {
		val = (char *) memchr(ValsKayCipher, val, 26) - ValsKayCipher;
		printf("%c", toupper('A' + val + 1));
	    }
	    else if (val >= 0 && val <= 25 && base == 10)
		printf("%c", toupper((unsigned char) ValsRev[val]));
	    else if (valbase >= 0 && valbase <= 25 && base != 10)
		printf("%c", toupper((unsigned char) ValsRev[valbase]));
	    else if (val == 26 && base == 10)
		printf("%c%c", 0xC3, swedish ? 0xA5 : 0xA4);
	    else if (val == 27 && base == 10)
		printf("%c%c", 0xC3, swedish ? 0xA4 : 0xB6);
	    else if (val == 28 && base == 10)
		printf("%c%c", 0xC3, swedish ? 0xB6 : 0xBC);
	    else if (val == 29 && base == 10)
		printf("%c%c", 0xC3, 0x9F);
	    else
		printf("<%s>", argv[i]);
	}
	printf("\n");
    }
    else
    {
	sum = mul ? 1 : 0;
	lastval = -1;
	sumVowels = 0;
	sumConsolents = 0;
	for (i = 0; i < argc; ++i)
	{
	    debug(1, "arg%d='%s'\n", i, argv[i]);

	    if (words) sum = mul ? 1 : 0;
	    if (Length)
	    {
		int val;
		val = strlen(argv[i]);
		if (DigitalRoot)
		    val = 1 + ((val - 1) % 9);
		printf("%d ", val);
		sum += val;
		continue;
	    }
	    if (ConsVowels)
	    {
		int v = 0;
		int j;
		c = 0;
		for (j = 0; j < (int) strlen(argv[i]); ++j)
		    if (tolower((unsigned char) argv[i][j]) == 'a') ++v;
		    else if (tolower((unsigned char) argv[i][j]) == 'e') ++v;
		    else if (tolower((unsigned char) argv[i][j]) == 'i') ++v;
		    else if (tolower((unsigned char) argv[i][j]) == 'o') ++v;
		    else if (tolower((unsigned char) argv[i][j]) == 'u') ++v;
		    else if (SometimesY
			&& tolower((unsigned char) argv[i][j]) == 'y') ++v;
		    else if (tolower((unsigned char) argv[i][j]) >= 'a'
			&& tolower((unsigned char) argv[i][j]) <= 'z') ++c;
		printf("%d/%d ", c, v);
		sumVowels += v;
		sumConsolents += c;
		continue;
	    }
	    for (p = (unsigned char *) argv[i]; *p; ++p)
	    {
		int val;

		if (p != (unsigned char *) argv[i] && SingleChar)
		    break;
		c = *p;
		if (ascii)
		    val = c;
		else if (unicode == 1)
		{
		    // German or Swedish umlaut code
		    unicode = 0;
		    switch (c)
		    {
		    case 0xA4:	
			if (swedish)
			    val = 28 + Aequals1 - 1;
			else
			    val = 27 + Aequals1 - 1;
			break;
		    case 0xA5:
			val = 27 + Aequals1 - 1;
			break;
		    case 0xB6:
			if (swedish)
			    val = 29 + Aequals1 - 1;
			else
			    val = 28 + Aequals1 - 1;
			break;
		    case 0xBC:
			val = 29 + Aequals1 - 1;
			break;
		    case 0x9F:
			val = 30 + Aequals1 - 1;
			break;
		    default:
			error(1, "Can't add unistd '%c' (0x%x)\n", c, c);
			break;
		    }
		}
		else if (shiftnumbers &&
		    ((c >= '!' && c <= '/')
		    || (c == '@') || (c == '^') || (c == ' ')
		    || (c == '>') || (c == '.')) )
		{
		    switch (c)
		    {
		    case '!': val = 1; break;
		    case '@': val = 2; break;
		    case '#': val = 3; break;
		    case '$': val = 4; break;
		    case '%': val = 5; break;
		    case '^': val = 6; break;
		    case '&': val = 7; break;
		    case '*': val = 8; break;
		    case '(': val = 9; break;
		    case ')': val = 0; break;
		    case ' ': printf(" "); continue;
		    case '>': printf(". "); continue;
		    case '.': printf(". "); continue;
		    default:
			break;
		    }
		}
		else if (c >= 'A' && c <= 'Z')
		    val = Vals[tolower(c) - 'a'] + Aequals1;
		else if (c >= 'a' && c <= 'z')
		    val = Vals[tolower(c) - 'a'] + Aequals1;
		else if (c >= '0' && c <= '9')
		    val = c - '0';
		else if (unicode == 0 && c == 0xC3)
		{
		    unicode = 1;
		    continue;
		}
		else if (c == ' ' || c == '	')
		    continue;
		else if (c == ',' || c == '.')
		    continue;
		else if (c == '(' || c == ')' || c == '+')
		{
		    printf("%c", c);
		    continue;
		}
		else  if(c == '*' && scrabble)
		{
		    ++p;
		    sum *= atoi((char *) p);
		    ++p;
		    break;
		}
		else if (Phone && c == '1')
		    val = 1;
		else if (Phone && c == '0')
		    val = 0;
		else
		    error(1, "Can't add '%c' (0x%x)\n", c, c);

		if (delta)
		{
		    int	tmp;
		    if (lastval < 0)
		    {
			lastval = val;
			continue;
		    }
		    tmp = val;
		    val -= lastval;
		    lastval = tmp;
		}

		if (modulus)
		{
		    while (val < 0)
			val += modulus;
		    val %= modulus;
		}

		if (num)
		{
		    if (Binary && val != 0)
			to_binary(val);
		    else
			printf(numfmt, (long long) val);
		    printf(" ");
		}
		if (mul)
		    sum *= val;
		else
		    sum += val;
	    }
	    if (DigitalRoot)
	    {
		sum = 1 + ((sum - 1) % 9);
	    }
	    if (words)
	    {
		if (num)
		    printf("= %lld\n", sum);
		else
		    printf("%lld ", sum);
	    }
	}
	if (num && !words)
	{
	    printf("= ");
	    printf(numfmt, sum);
	}
	else if (Length)
	{
	    if (DigitalRoot)
		sum = 1 + ((sum - 1) % 9);
	    printf("= %lld", sum);
	}
	// printf("sum of '%s' is %lld\n", argv[0], sum);
	if (words && num && !Length)
	    ;
	else if (words && !num)
	    printf("\n");
	else if (ConsVowels)
	    printf("= %lld/%lld\n", sumConsolents, sumVowels);
	else if (num || Length)
	    printf("\n");
	else if (Total)
	    printf("%lld	%lld	%lld\n", sum, Total-sum, Total);
	else
	    printf("%lld\n", sum);
    }

    exit(0);
}
