PREFIX?=$$HOME

CFLAGS += -Wall

UNAME := $(shell uname)
ROOT=root
SED=sed
ifeq ($(UNAME),Darwin)
    SED=gsed
    #ROOT=sudo
endif
ifeq ($(UNAME),FreeBSD)
    SED=gsed
endif

NULL=
SHELLS=	geo-nearest geo-code geo-count geo-usernum geo-waypoint \
	geo-poi \
	geo-keyword \
	geo-map geo-newest geo-found geo-placed \
	geo-demand \
	geo-pqdownload \
	geo-myfinds \
	geo-gid \
	geo-gpx \
	geo-rehides \
	geo-density \
	geo-gpxmail \
	geo-gpxprocess \
	geo-2gpsdrive \
	geo-2tangogps \
	geo-circles \
	geo-trilateration \
	geo-triangulation \
	geo-polygon \
	geo-coords \
	geo-project \
	geo-additional \
	rect2geomap \
	geo-dist \
	gpx2html \
	geo-procmail \
	geo-html2gpx \
	gpx-merge \
	gpx-photos \
	gpx-ftf \
	gpx-logs \
	gpx-loghistory \
	geo-pqs \
	geo-state \
	geo-intersect \
	geo-suffix \
	geo-sdt \
	geo-ts2geko \
	geo-uniq \
	geo-gccode2id \
	geo-id2gccode \
	geo-firefox \
	gpx-stats \
	gpx-finders \
	mngca mngca-newmap mngca-logs \
	nc-nearest \
	nc-newest \
	oc-nearest \
	oc-newest \
	ok-nearest \
	ok-newest \
	ll2osg \
	osg2ll \
	ll2maidenhead \
	maidenhead2ll \
	ll2ggl \
	ggl2ll \
	ll2usng \
	usng2ll \
	ll2rd \
	rd2ll \
	bing2ll \
	ll2geohash \
	geohash2ll \
	geo-htmltbl2db \
	geo-mystery \
	geo-correct-coords \
	geo-loran-c \
	gpx-unfound \
	geo-wordsearch \
	reverse-montage \
	geo-crossword \
	geo-phone2word \
	geo-sub \
	geo-zipcode \
	geo-char-at \
	geo-ocr \
	geo-alphametic \
	geo-text2qrcode \
	geo-excel2qrcode \
	mayan-long-count \
	navaho-code-talkers \
	tap-code \
	braille2text \
	adddigits \
	geo-incomplete-coords \
	decimal2cryptogram \
	smilies2cryptogram \
	geo-thumbnails \
	negadecimal \
	wherigo2jpg \
	wherigo2lua \
	urwigo-decode \
	reverse-wherigo \
	geo-algebraic-expressions \
	geo-morse \
	geo-lewis-and-clark \
	geo-text2numbers \
	segment2text \
	spiritdvd2text \
	baconian2text \
	geo-bacon \
	atomic-symbol-to-atomic-number \
	atomic-symbol-to-period-or-group \
	atomic-number-to-text \
	geo-rotate-text \
	geo-battleship \
	fibonacci-coding \
	balanced-ternary \
	zonepoint2map \
	geo-compare-images \
	geo-clock-angle \
	geo-fax \
	geo-timed-cache \
	nono2cross+a \
	nono2teal \
	nono2jsolver \
	geo-nonogram \
	pbnsolve-wrapper \
	anybase2anybase \
	add-pyramids \
	geo-slash-backslash \
	geo-slash-pipe \
	radio-orphan-annie \
	stickman2text \
	geo-math-functions \
	geo-addsub \
	$(NULL)

	# Private stock
	ifeq ($(wildcard geo-soon*.sh),geo-soon.sh)
		SHELLS+=geo-soon
		# SHELLS+=geo-unk
		SHELLS+=update-caches
		SHELLS+=geo-pocket-query-newest
	endif

CPROGS= \
	addletters \
	lethist \
	pgpdb2txt \
	$(NULL)

FILES= \
	ChangeLog \
	geo-bot \
	geo-code.sh geo-waypoint.sh \
	geo-common geo-common-gc geo-common-nc geo-common-oc geo-common-ok \
	geo-common-gpsdrive geo-common-tangogps \
	geo-found.sh geo-nearest.sh geo-newest.sh geo-placed.sh \
	geo-keyword.sh \
	geo-count.sh geo-usernum.sh \
	geo-demand.sh \
	geo-pqdownload.sh \
	geo-myfinds.sh \
	geo-gid.sh \
	geo-rehides \
	geo-density.sh \
	geo-gpx.sh \
	geo-gpxmail \
	geo-gpxprocess \
	geo-circles.sh \
	geo-trilateration.sh \
	geo-triangulation.sh \
	geo-polygon.sh \
	geo-coords.sh \
	geo-project.sh \
	geo-additional.sh \
	geo-2gpsdrive.sh \
	geo-2tangogps.sh \
	rect2geomap \
	gpx2html \
	geo-html2gpx \
	geo-procmail \
	gpx-merge \
	gpx-ftf \
	gpx-logs \
	gpx-loghistory \
	geo-pqs \
	geo-state \
	geo-intersect.sh \
	geo-suffix \
	geo-sdt \
	geo-ts2geko \
	geo-uniq \
	geo-gccode2id \
	geo-id2gccode \
	geo-firefox.sh \
	gpx-stats \
	gpx-finders \
	includer ncftprm myftpput Makefile README TODO \
	ncftpdir2html \
	mngca mngca-newmap mngca-logs \
	geo-poi pgpdb2txt.c \
	addletters.c \
	lethist.c \
	geo-map.sh \
	gpx-photos.sh \
	geo-dist.sh \
	geodetics.html \
	greatcircle.html \
	images/*.gif \
	test.tiger \
	utm/Makefile \
	utm/ll2utm.c \
	utm/utm2ll.c \
	utm/tm.c \
	utm/ups.c \
	utm/utm.c \
	utm/Prefs.h \
	nc-nearest.sh \
	nc-newest.sh \
	oc-nearest.sh \
	oc-newest.sh \
	ok-nearest.sh \
	ok-newest.sh \
	hires6 \
	hires9 \
	geometry/geometry*.[CH] \
	ll2osg.sh \
	osg2ll.sh \
	ll2maidenhead.sh \
	maidenhead2ll.sh \
	ll2usng.sh \
	usng2ll.sh \
	ll2rd.sh \
	rd2ll.sh \
	ll2ggl \
	ggl2ll \
	bing2ll \
	geohash2ll \
	ll2geohash.sh \
	txt2man \
	txt2man.macros \
	geo-cs-html2db.sh \
	countries.db \
	states.db \
	geo-countries-states.7in \
	update-caches \
	geo-wordsearch \
	reverse-montage \
	geo-crossword \
	geo-htmltbl2db \
	geo-mystery \
	geo-correct-coords.sh \
	geo-loran-c \
	gpx-unfound.sh \
	geo-phone2word.sh \
	english.dic \
	navaho.dic \
	french \
	ngerman \
	spanish \
	geo-sub \
	geo-zipcode.sh \
	geo-char-at \
	geo-ocr \
	geo-alphametic \
	geo-text2qrcode \
	geo-excel2qrcode \
	mayan-long-count \
	navaho-code-talkers \
	tap-code \
	braille2text \
	adddigits \
	geo-incomplete-coords \
	decimal2cryptogram \
	smilies2cryptogram \
	geo-thumbnails \
	negadecimal \
	wherigo2jpg \
	wherigo2lua \
	urwigo-decode \
	reverse-wherigo \
	geo-algebraic-expressions \
	geo-morse \
	geo-lewis-and-clark \
	geo-text2numbers \
	segment2text \
	spiritdvd2text \
	baconian2text \
	geo-bacon \
	atomic-symbol-to-atomic-number \
	atomic-symbol-to-period-or-group \
	atomic-number-to-text \
	geo-rotate-text \
	geo-battleship \
	fibonacci-coding \
	balanced-ternary \
	zonepoint2map \
	geo-compare-images \
	geo-clock-angle \
	geo-fax \
	geo-timed-cache \
	nono2cross+a \
	nono2teal \
	nono2jsolver \
	geo-nonogram \
	pbnsolve-wrapper \
	StyledMarker.js \
	anybase2anybase \
	add-pyramids \
	geo-slash-backslash \
	geo-slash-pipe \
	radio-orphan-annie \
	stickman2text \
	geo-math-functions \
	geo-addsub \
	$(NULL)

#
#	There is a lot of code common to these scripts, especially the
#	query scripts.  But I like to be able to hand someone a single
#	file and have it be self-contained and complete.  Plus, it lends
#	itself to "quick hacks".  So rather than create a library of
#	shell functions, I include them inline in each script.
#
.SUFFIXES: .sh .1 .raw .png

% : %.sh
	rm -f $@; ./includer -tsh $< >$@ || { rm -f $@; exit 1; }; chmod +x-w $@

%.1 : % Makefile txt2man txt2man.macros
	./$< -? 2>&1 | LC_ALL=C ./txt2man -t $< -s 1 >$@

%.png: %.raw raw2png
	./raw2png $<

#
#	The usual build rules: all install clean
#
all:	all-test $(CPROGS) $(SHELLS) geo-cs-html2db
	cd utm; $(MAKE) all

MACOSX_stdio=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/stdio.h

all-test:
	#
	# Dependencies
	#
	@if ! type $(CC) >/dev/null 2>&1; then \
	    echo "      ***"; \
            echo "      *** Error: $(CC) is not installed!"; \
            echo "      ***"; \
            echo "      *** Install Software Development package (yum install gcc)"; \
            echo "      ***"; \
            exit 1; \
	fi
	@if [ "`ls $(MACOSX_stdio) 2> /dev/null`" != "" ]; then \
	    : ; \
	elif ! test -f /usr/include/stdio.h; then \
	    echo "      ***"; \
	    echo "      *** Error: /usr/include/stdio.h is not installed!"; \
	    echo "      ***"; \
	    echo "      *** Install Software Development package (yum install gcc)"; \
	    echo "      *** for Ubuntu: sudo apt-get install build-essential"; \
	    echo "      ***"; \
	    exit 1; \
	fi
	@if ! type gpsbabel >/dev/null 2>&1; then \
            echo "      ***"; \
            echo "      *** Error: gpsbabel is not installed!"; \
            echo "      ***"; \
            echo "      *** Install gpsbabel package (yum install gpsbabel)"; \
            echo "      ***"; \
            exit 1; \
        fi
	@if ! type curl >/dev/null 2>&1; then \
            echo "      ***"; \
            echo "      *** Error: curl is not installed!"; \
            echo "      ***"; \
            echo "      *** Install curl package (yum install curl)"; \
            echo "      ***"; \
            exit 1; \
        fi
	@if ! type dos2unix >/dev/null 2>&1; then \
            echo "      ***"; \
            echo "      *** Error: dos2unix is not installed!"; \
            echo "      ***"; \
            echo "      *** Install dos2unix package (yum install dos2unix)"; \
            echo "      *** (apt-get install dos2unix OR tofrodos)"; \
            echo "      ***"; \
            exit 1; \
        fi
	@if ! type dc >/dev/null 2>&1; then \
            echo "      ***"; \
            echo "      *** Error: dc is not installed!"; \
            echo "      ***"; \
            echo "      *** Install bc OR dc package (yum install bc dc)"; \
            echo "      ***"; \
            exit 1; \
        fi
	@if ! type units >/dev/null 2>&1; then \
            echo "      ***"; \
            echo "      *** Error: units is not installed!"; \
            echo "      ***"; \
            echo "      *** Install units package (yum install units)"; \
            echo "      ***"; \
            exit 1; \
        fi
	@if ! type uuencode >/dev/null 2>&1; then \
            echo "      ***"; \
            echo "      *** Error: uuencode is not installed!"; \
            echo "      ***"; \
            echo "      *** Install sharutils package (yum install sharutils)"; \
            echo "      ***"; \
            exit 1; \
        fi
	@if ! type gawk >/dev/null 2>&1; then \
            echo "      ***"; \
            echo "      *** Error: gawk is not installed!"; \
            echo "      ***"; \
            echo "      *** Install gawk package (yum install gawk)"; \
            echo "      ***"; \
            exit 1; \
        fi

geo-newest-cs: includer Makefile countries.db states.db
	$(SED) \
	    -e '/^#/d' \
	    -e 's/\t/|/g' \
	    -e 's/|*|/|/g' \
	    -e 's/\([^|]*\)|\(.*\)/\2) id=\1;;/' \
	    -e "s/'//g" \
	    -e "s/\\\\ ([^)]*)//g" \
	    < states.db > $@
	echo >>$@
	$(SED) \
	    -e '/^#/d' \
	    -e 's/\t/|/g' \
	    -e 's/|*|/|/g' \
	    -e 's/\([^|]*\)|\(.*\)/\2) cid=\1;;/' \
	    -e "s/\\\\ ([^)]*)//g" \
	    < countries.db >> $@

geo-demand-cs: includer Makefile countries.db states.db
	$(SED) \
	    -e '/^#/d' \
	    -e 's/\t/|/g' \
	    -e 's/|*|/|/g' \
	    -e 's/\([^|]*\)|\(.*\)/	\2) states="$$states -d$${CTL}lbStates=\1";;/' \
	    -e "s/'//g" \
	    -e "s/\\\\ ([^)]*)//g" \
	    < states.db > $@
	echo >>$@
	$(SED) \
	    -e '/^#/d' \
	    -e 's/\t/|/g' \
	    -e 's/|*|/|/g' \
	    -e 's/\([^|]*\)|\(.*\)/	\2) countries="$$countries -d$${CTL}lbCountries=\1";;/' \
	    -e "s/\\\\ ([^)]*)//g" \
	    < countries.db >> $@

geo-newest: geo-common geo-common-gc geo-common-gpsdrive Makefile geo-newest-cs
geo-demand: geo-common geo-common-gc Makefile geo-demand-cs

geo-nearest: geo-common geo-common-gc geo-common-gpsdrive Makefile
geo-found: geo-common geo-common-gc geo-common-gpsdrive Makefile
geo-placed: geo-common geo-common-gc geo-common-gpsdrive Makefile
geo-keyword: geo-common geo-common-gc geo-common-gpsdrive Makefile
geo-pqdownload: geo-common geo-common-gc Makefile
geo-additional: geo-common geo-common-gc Makefile
geo-myfinds: geo-common geo-common-gc Makefile
geo-gid: geo-common geo-common-gc geo-common-gpsdrive Makefile
geo-gpx: geo-common geo-common-gpsdrive Makefile
geo-2gpsdrive: geo-common geo-common-gpsdrive Makefile
geo-2tangogps: geo-common geo-common-tangogps Makefile
geo-count: geo-common geo-common-gc Makefile
geo-density: geo-common geo-common-gc Makefile
geo-map: geo-common geo-common-gc geo-images StyledMarker.js Makefile
geo-circles: geo-common Makefile
geo-trilateration: geo-common Makefile
geo-triangulation: geo-common Makefile
geo-polygon: geo-common Makefile
geo-intersect: geo-common Makefile
geo-coords: geo-common Makefile
geo-project: geo-common Makefile
geo-code: geo-common Makefile
geo-zipcode: geo-common Makefile
geo-waypoint: geo-common geo-common-gpsdrive Makefile
geo-dist: geo-common Makefile
gpx-photos: geo-common Makefile
nc-nearest: geo-common geo-common-nc geo-common-gpsdrive Makefile
nc-newest: geo-common geo-common-nc geo-common-gpsdrive Makefile
oc-nearest: geo-common geo-common-oc geo-common-gpsdrive Makefile
oc-newest: geo-common geo-common-oc geo-common-gpsdrive Makefile
ok-nearest: geo-common geo-common-ok geo-common-gpsdrive Makefile
ok-newest: geo-common geo-common-ok geo-common-gpsdrive Makefile
ll2geohash: geo-common Makefile
ll2maidenhead: geo-common Makefile
maidenhead2ll: geo-common Makefile
ll2usng: geo-common Makefile
usng2ll: geo-common Makefile
ll2rd: geo-common Makefile
rd2ll: geo-common Makefile
ll2osg: geo-common Makefile
osg2ll: geo-common Makefile
geo-correct-coords: geo-common geo-common-gc Makefile
geo-pocket-query-newest: geo-common geo-common-gc Makefile
geo-usernum: geo-common geo-common-gc Makefile
geo-cs-html2db: geo-common geo-common-gc Makefile
geo-soon: geo-common geo-common-gc geo-common-gpsdrive Makefile
gpx-unfound: geo-common geo-common-oc Makefile

geo-images: images Makefile
	find images -type f | sed '/CVS/d' | \
	    cpio -oc | uuencode /tmp/geo/images.cpio > $@ \
		|| (echo "*** You need to get the 'sharutils' package"; exit 1)

calcxy: calcxy.c
	$(CC) calcxy.c -o $@ -lm

CROSSWORD_LANGS=french spanish ngerman

install: all
	[ -d $(PREFIX)/bin/ ] || mkdir $(PREFIX)/bin/
	install $(SHELLS) $(PREFIX)/bin/
	install $(CPROGS) $(PREFIX)/bin
	install gpx2html $(PREFIX)/bin/
	cd utm; $(MAKE) install
	install -d $$HOME/public_html/
	install geodetics.html $$HOME/public_html/
	install greatcircle.html $$HOME/public_html/
	[ -d $(PREFIX)/lib/ ] || mkdir $(PREFIX)/lib/
	[ -d $(PREFIX)/lib/geo ] || mkdir $(PREFIX)/lib/geo
	install -m 644 english.dic $(PREFIX)/lib/geo
	install -m 644 navaho.dic $(PREFIX)/lib/geo
	install -m 644 $(CROSSWORD_LANGS) $(PREFIX)/lib/geo

uninstall:
	if [ -d $(PREFIX)/bin/ ]; then \
	    cd $(PREFIX)/bin/ && rm -f $(SHELLS); \
	    cd $(PREFIX)/bin/ && rm -f $(CPROGS); \
	fi
	if [ -d $$HOME/public_html ]; then \
	    cd $$HOME/public_html && rm -f geodetics.html greatcircle.html; \
	fi
	if [ -d $(PREFIX)/lib/geo ]; then \
	    cd $(PREFIX)/lib/geo && rm -f english.dic navaho.dic $(CROSSWORD_LANGS); \
	fi

clean:
	rm -f geo-found geo-nearest geo-newest geo-placed geo-count
	rm -f geo-map geo-code geo-waypoint geo-keyword
	rm -f geo-circles geo-trilateration geo-triangulation geo-polygon
	rm -f geo-project geo-intersect
	rm -f geo-2gpsdrive geo-2tangogps
	rm -f geo-demand geo-pqdownload geo-gpx geo-gid
	rm -f geo-dist geo-density geo-coords geo-myfinds
	rm -f geo-images
	rm -f gpx-photos
	rm -f geo-firefox
	rm -f geo-usernum
	rm -f geo-pocket-query-newest
	rm -f geo-soon geo-additional
	rm -f nc-nearest nc-newest
	rm -f oc-nearest oc-newest
	rm -f ok-nearest ok-newest
	rm -f ll2maidenhead maidenhead2ll ll2usng usng2ll ll2rd rd2ll
	rm -f ll2osg osg2ll ll2geohash
	rm -f geo-correct-coords
	rm -f geo-phone2word
	rm -f gpx-unfound
	rm -f geo-cs-html2db
	rm -f geo-demand-cs geo-newest-cs
	rm -f *.tar.gz
	rm -f Readme
	rm -f tomtom-*.png
	rm -f $(CPROGS)
	rm -f FredericksburgCityVA-PG.txt
	cd utm; $(MAKE) clean
	rm -f *.1 *.7
	rm -f manual.pdf

MANPAGES1=$(SHELLS:%=%.1) $(CPROGS:%=%.1) utm/ll2utm.1 utm/utm2ll.1
MANPAGES7=geo-countries-states.7
MANPAGES=$(MANPAGES1) $(MANPAGES7)
GROFF=groff
ifeq ($(PREFIX),$$HOME)
    DOCDIR=/usr/share/doc/geo/
    MANDIR=/usr/share/man/
else
    DOCDIR=$(PREFIX)/share/doc/geo/
    MANDIR=$(PREFIX)/share/man/
endif

geo-countries-states.7: geo-countries-states.7in states.db countries.db Makefile
	rm -f $@; ./includer -tman $< | \
	    sed '/^#/d' > $@ || { rm -f $@; exit 1; }; chmod -x-w $@

# Next 4 lines are due to Cygwin!
utm/ll2utm.1: utm/ll2utm
	./$< -? 2>&1 | LC_ALL=C ./txt2man -t $< -s 1 >$@

utm/utm2ll.1: utm/utm2ll
	./$< -? 2>&1 | LC_ALL=C ./txt2man -t $< -s 1 >$@
# End

man: $(MANPAGES) manual.pdf

install-man: man
	install $(MANPAGES1) $(MANDIR)/man1/
	install $(MANPAGES7) $(MANDIR)/man7/
	install -d -m 755 $(DOCDIR)
	install manual.pdf $(DOCDIR)

manual.pdf: $(MANPAGES)
	$(GROFF) -t -man `ls $(MANPAGES) | sort` | ps2pdf - $@

#
#	The author (Rick) does this:
#
w:	all
	$(MAKE) man install 
	$(ROOT) $(MAKE) install-man

#
#	Populate the website
#
NOW := $(shell date +"%y-%m-%d-%H-%M-%S")
tar:
	rm -f *.tar.gz
	HERE=`basename $$PWD`; \
        /bin/ls $(FILES) | \
        sed -e "s?^?$$HERE/?" | \
        (cd ..; tar -c -z -f $$HERE/$$HERE-$(NOW).tar.gz -T-)

WEBSITE=~/.ncftp-website
WEBDIR=geo
FTPOPTS=
FTPOPTS=-S
web:	tar webfiles webindex webmn webss

webfiles: manual.pdf
	-./ncftprm $(FTPOPTS) -f $(WEBSITE) $(WEBDIR) '*.tar.gz';
	./myftpput $(FTPOPTS) -f $(WEBSITE) $(WEBDIR) \
		ChangeLog manual.pdf $(SHELLS) *.tar.gz;

oldfiles:
	./myftpput $(FTPOPTS) -f $(WEBSITE) $(WEBDIR) \
		README ChangeLog $(SHELLS) pgpdb2txt.c *.tar.gz;

webindex:
	./myftpput $(FTPOPTS) -f $(WEBSITE) $(WEBDIR) \
	    README index.php favicon.png;

webss: tomtom-1.png tomtom-2.png
	./myftpput $(FTPOPTS) -f $(WEBSITE) $(WEBDIR) \
	    tomtom-*.png geo-map.png geo-gmap.png geo-map-ts.png win10.png;

webmn:
	./myftpput $(FTPOPTS) -f $(WEBSITE) mngca \
	    geodetics.html greatcircle.html geochecker.html;

#
#	Regression tests
#
test:
	geo-gpx -ogpx GC3T7TK | grep "<wpt"
	geo-gid GC4TAX4
	geo-code "952-476-8329"
	geo-code "" "Mankato, MN"
	geo-code -t house "47071 Bayside Parkway" 94538 
	geo-code -n "Bob's House" -t house "47071 Bayside Parkway" 94538 
	geo-code -ogpsdrive.sql -n "Any House USA" -t house \
	    "47071 Bayside Parkway" 94538 
	geo-nearest -n 40
	geo-newest -n 40

test_at:
	./geo-code -D1 "Ebendorferstrasse 4" "A-1082 Vienna" at
test_be:
	./geo-code -D1 "Interleuvenlaan 5" "B-3000 Leuven" be
test_de:
	./geo-code -D1 "Schlossplatz 10" "76131 Karlsruhe" de
test_dk:
	./geo-code -D1 "Asiatisk Plads 2" "DK-1448 Copenhagen K" dk
test_fi:
	./geo-code -D1 "Mannerheimintie 10" "00100 Helsinki" fi
test_fr:
	./geo-code -D1 "116, avenue du Président Kennedy" "75016 Paris" fr
test_it:
	./geo-code -D1 "Via Tevere No 44" "00198 Rome" it
test_ca:
	./geo-code -D1 "1 Yonge Street" "M5E 1W7" ca
	./geo-code -D1 "1 Yonge Street" "Toronto, Ontario" ca
	./geo-code -D1 "1 Yonge Street" "Toronto, ON M5E 1W7" ca

ptest:	pgpdb2txt
	./pgpdb2txt -F FredericksburgCityVA-PG.pdb \
	    | tee  FredericksburgCityVA-PG.txt
