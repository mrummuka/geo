#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Convert telephone numbers to word(s)

SYNOPSIS
    `basename $PROGNAME` [options] [numbers]

DESCRIPTION
    Convert telephone numbers to word(s).  It can use command line "numbers"
    or stdin. Also, there are ROT-13 versions of zero, one, ... ninety and
    north, south, east, west, hundred, etc.

OPTIONS
    -a		Use ancient text, 1st digit is place, 2nd digit is 1, 2, 3, 4

		i.e. MTS Audio Response Unit (IBM 7772) developed in 1964

    -c		Use count instead

    -D lvl	Debug level

EXAMPLE
    Convert:

	$ geo-phone2word 43246
	idaho

	$ geo-phone2word -c 66 666 777 8 44 
	north

	$ geo-phone2word 7243 227 488345 48243627 78884 8427377 282745 227
	7243:   said rage sage paid page raid four(rot13) 
	227:    bar bas cap bbq cbs abs car bbs one(rot13) 
	488345: thirty(rot13) 
	48243627:       thousand(rot13) 
	78884:  eight(rot13) 
	8427377:        hundred(rot13) 
	282745: ninety(rot13) 
	227:    bar bas cap bbq cbs abs car bbs one(rot13) 

	$ geo-phone2word -a
	N819132628193O744392R33
	63738193T744392H814273
	32327432833262636232
	W324341428193E94327363
	S819163T74328332628191
	32628193
	twentysixfortysixthreesevenoneeightyzerotwoseventwenty

SEE ALSO
	\$HOME/lib/geo/english.dic

	/usr/lib/geo/english.dic
EOF

	exit 1
}

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
MODE=0
while getopts "acD:h?" opt
do
	case $opt in
	a)	MODE=2;;
	c)	MODE=1;;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

if [ -s "$HOME/lib/geo/english.dic" ]; then
    LIBGEO=$HOME/lib/geo
elif [ -s "/usr/lib/geo/english.dic" ]; then
    LIBGEO=/usr/lib/geo
else
    error "Can't find 'english.dic'"
fi

one_word_per_line() {
    tr -cs "[:alnum:]" "\n"
}

docount() {
    awk '
    {
	# Example: 111222344 == 111 222 3 44
	for (i = 1; i <= length($0); ++i)
	{
	    c = substr($0, i, 1)
	    if (c != oc && oc != "")
		printf " "
	    printf "%s", c
	    oc = c
	}
	printf "\n"
    }' |
    one_word_per_line |
    awk '
    /2222/ { printf "2"; next}
    /222/ { printf "c"; next}
    /22/ { printf "b"; next}
    /2/ { printf "a"; next}
    /3333/ { printf "3"; next}
    /333/ { printf "f"; next}
    /33/ { printf "e"; next}
    /3/ { printf "d"; next}
    /4444/ { printf "4"; next}
    /444/ { printf "i"; next}
    /44/ { printf "h"; next}
    /4/ { printf "g"; next}
    /5555/ { printf "5"; next}
    /555/ { printf "l"; next}
    /55/ { printf "k"; next}
    /5/ { printf "j"; next}
    /6666/ { printf "6"; next}
    /666/ { printf "o"; next}
    /66/ { printf "n"; next}
    /6/ { printf "m"; next}
    /77777/ { printf "7"; next}
    /7777/ { printf "s"; next}
    /777/ { printf "r"; next}
    /77/ { printf "q"; next}
    /7/ { printf "p"; next}
    /8888/ { printf "8"; next}
    /888/ { printf "v"; next}
    /88/ { printf "u"; next}
    /8/ { printf "t"; next}
    /99999/ { printf "9"; next}
    /9999/ { printf "z"; next}
    /999/ { printf "y"; next}
    /99/ { printf "x"; next}
    /9/ { printf "w"; next}
    { printf "%s", $0 }
    END { printf "\n" }
    '
}

doword() {
    case "$1" in
    [0-9]*)
		t=`echo $i | tr -d '.,/' `
		printf "$t: "
		grep "^$t," $LIBGEO/english.dic |
		    sed 's/^.*,//' | tr "\012" " "
		echo
		;;
    "#"*|"*"*)	printf "$i:\n";;
    *)      error "Non-numeric phone '$i'";;
    esac
}

doancient() {
    tr -c -d "0-9" | sed 's/../& /g' | one_word_per_line |
    awk '
    /21/ { printf "a"; next}
    /22/ { printf "b"; next}
    /23/ { printf "c"; next}
    /31/ { printf "d"; next}
    /32/ { printf "e"; next}
    /33/ { printf "f"; next}
    /41/ { printf "g"; next}
    /42/ { printf "h"; next}
    /43/ { printf "i"; next}
    /51/ { printf "j"; next}
    /52/ { printf "k"; next}
    /53/ { printf "l"; next}
    /61/ { printf "m"; next}
    /62/ { printf "n"; next}
    /63/ { printf "o"; next}
    /71/ { printf "p"; next}
    /72/ { printf "q"; next}
    /73/ { printf "r"; next}
    /74/ { printf "s"; next}
    /81/ { printf "t"; next}
    /82/ { printf "u"; next}
    /83/ { printf "v"; next}
    /91/ { printf "w"; next}
    /92/ { printf "x"; next}
    /93/ { printf "y"; next}
    /94/ { printf "z"; next}
    END { printf "\n" }
    '
}

#
#	Main Program
#
case $MODE in
0)	# Word
    if [ $# = 0 ]; then
	one_word_per_line | while read i; do
	    doword $i
	done
    else
	for i in $*; do
	    doword $i
	done
    fi
    ;;
1)	# Count
    if [ $# = 0 ]; then
	docount
    else
	echo $* | docount
    fi
    ;;
2)	# Ancient two digits
    if [ $# = 0 ]; then
	doancient
    else
	echo $* | doancient
    fi
    ;;
*)	error "Mode is out of range"
esac
