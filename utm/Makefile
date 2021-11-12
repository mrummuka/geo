PREFIX?=$$HOME
CFLAGS=-O -Wall
PROGS=ll2utm utm2ll

all: $(PROGS)

install: all
	install $(PROGS) $(PREFIX)/bin/

clean:
	-rm -f $(PROGS)

ll2utm: ll2utm.c Prefs.h utm.c tm.c ups.c
	$(CC) $(CFLAGS) ll2utm.c -lm -o $@

utm2ll: utm2ll.c Prefs.h utm.c tm.c ups.c
	$(CC) $(CFLAGS) utm2ll.c -lm -o $@
