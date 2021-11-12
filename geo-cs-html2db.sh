#!/bin/bash

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - get states and countries into awk DB files

SYNOPSIS
    `basename $PROGNAME` 

DESCRIPTION
	`basename $PROGNAME` gets an HTML file from
	    $PQURL
	and massages it into countries.db and states.db.

OPTIONS
        -D lvl          Debug level [$DEBUG]

FILES
	countries.db
	states.db

SEE ALSO
	geo-countries-states(7)
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
PQURL="https://www.geocaching.com/pocket/gcquery.aspx"
UPDATE_URL=$WEBHOME/geo-demand
UPDATE_FILE=geo-demand.new
CTL="ctl00%24ContentBody%24"
DEBUG=0

read_rc_file

#
#       Process the options
#
while getopts "D:h?-" opt
do
    case $opt in
    D)	DEBUG="$OPTARG";;
    h|\?|-) usage;;
    esac
done
shift `expr $OPTIND - 1`

DBGCMD_LVL=2
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi
if [ $NOCOOKIES = 1 ]; then
    CRUFT="$CRUFT $COOKIE_FILE"
fi

#
#	Main Program
#

#
#	Login to gc.com
#
if [ "$DEBUG" -lt 3 ]; then
    gc_login "$USERNAME" "$PASSWORD"
fi

REPLY=$TMP-reply.html; CRUFT="$CRUFT $REPLY"

if [ "$DEBUG" -lt 3 ]; then
    # Get viewstate
    dbgcmd curl $CURL_OPTS -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	"$PQURL" > $REPLY

    gc_getviewstate $REPLY
    echo=
else
    echo=echo
fi

rm -f countries.db states.db

sed < $REPLY \
    -e '1,/"ctl00_ContentBody_lbCountries/d' \
    -e '/<.select>/,$d' \
    -e 's/.*<option.* value="//g' \
    -e 's/ *<.option>.*//g' \
    -e 's/ (.*)//g' \
    -e 's/ /\\ /g' \
    -e 's/">/\t/g' \
    -e 's/&#39;/\\ /g' \
    -e 's/\xc3\xa7/c/g' \
    -e 's/\xc3\xa9/e/g' \
    -e 's/\xc3\xb4/o/g' \
    -e '/^\r$/,$d'\
| tr [A-Z] [a-z] \
| awk -F '	' '
$2 == "afghanistan" { zz=".af"; zzz=".afg" }
$2 == "aland\\ islands" { zz=".ax"; zzz=".ala" }
$2 == "albania" { zz=".al"; zzz=".alb" }
$2 == "algeria" { zz=".dz"; zzz=".dza" }
$2 == "american\\ samoa" { zz=".as"; zzz=".asm" }
$2 == "andorra" { zz=".ad"; zzz=".and" }
$2 == "angola" { zz=".ao"; zzz=".ago" }
$2 == "anguilla" { zz=".ai"; zzz=".aia" }
$2 == "antarctica" { zz=".aq"; zzz=".ata" }
$2 == "antigua\\ and\\ barbuda" { zz=".ag"; zzz=".atg" }
$2 == "argentina" { zz=".ar"; zzz=".arg" }
$2 == "armenia" { zz=".am"; zzz=".arm" }
$2 == "aruba" { zz=".aw"; zzz=".abw" }
$2 == "australia" { zz=".au"; zzz=".aus" }
$2 == "austria" { zz=".at"; zzz=".aut" }
$2 == "azerbaijan" { zz=".az"; zzz=".aze" }
$2 == "bahamas" { zz=".bs"; zzz=".bhs" }
$2 == "bahrain" { zz=".bh"; zzz=".bhr" }
$2 == "bangladesh" { zz=".bd"; zzz=".bgd" }
$2 == "barbados" { zz=".bb"; zzz=".brb" }
$2 == "belarus" { zz=".by"; zzz=".blr" }
$2 == "belgium" { zz=".be"; zzz=".bel" }
$2 == "belize" { zz=".bz"; zzz=".blz" }
$2 == "benin" { zz=".bj"; zzz=".ben" }
$2 == "bermuda" { zz=".bm"; zzz=".bmu" }
$2 == "bhutan" { zz=".bt"; zzz=".btu" }
$2 == "bolivia" { zz=".bo"; zzz=".bol" }
$2 == "bonaire" { zz=".bq"; zzz=".bes" }
$2 == "bonaire,\\ sint\\ eustatius\\ and\\ saba" { zz=".bq"; zzz=".bes" }
$2 == "bosnia\\ and\\ herzegovina" { zz=".ba"; zzz=".bih" }
$2 == "bosnia" { zz=".ba"; zzz=".bih" }
$2 == "botswana" { zz=".bw"; zzz=".bwa" }
$2 == "bouvet\\ island" { zz=".bv"; zzz=".bvt" }
$2 == "brazil" { zz=".br"; zzz=".bra" }
$2 == "british\\ indian\\ ocean\\ territories" { zz=".io"; zzz=".iot" }
$2 == "british\\ indian\\ ocean\\ territory" { zz=".io"; zzz=".iot" }
$2 == "british\\ virgin\\ islands" { zz=".vg"; zzz=".vgb" }
$2 == "brunei" { zz=".bn"; zzz=".brn" }
$2 == "bulgaria" { zz=".bg"; zzz=".bgr" }
$2 == "burkina\\ faso" { zz=".bf"; zzz=".bfa" }
$2 == "burundi" { zz=".bi"; zzz=".bdi" }
$2 == "cambodia" { zz=".kh"; zzz=".khm" }
$2 == "cameroon" { zz=".cm"; zzz=".cmr" }
$2 == "canada" { zz=".ca"; zzz=".can" }
$2 == "cape\\ verde" { zz=".cv"; zzz=".cpv" }
$2 == "cabo\\ verde" { zz=".cv"; zzz=".cpv" }
$2 == "cayman\\ islands" { zz=".ky"; zzz=".cym" }
$2 == "central\\ african\\ republic" { zz=".cf"; zzz=".caf" }
$2 == "chad" { zz=".td"; zzz=".tcd" }
$2 == "chile" { zz=".cl"; zzz=".chl" }
$2 == "china" { zz=".cn"; zzz=".chn" }
$2 == "christmas\\ island" { zz=".cx"; zzz=".cxr" }
$2 == "cocos\\ (keeling)\\ islands" { zz=".cc"; zzz=".cck" }
$2 == "cocos\\ islands" { zz=".cc"; zzz=".cck" }
$2 == "colombia" { zz=".co"; zzz=".col" }
$2 == "comoros" { zz=".km"; zzz=".com" }
$2 == "congo" { zz=".cg"; zzz=".cog" }
$2 == "cook\\ islands" { zz=".ck"; zzz=".cok" }
$2 == "costa\\ rica" { zz=".cr"; zzz=".cri" }
$2 == "cote\\ d\\ ivoire" { zz=".ci"; zzz=".civ" }
$2 == "croatia" { zz=".hr"; zzz=".hrv" }
$2 == "cuba" { zz=".cu"; zzz=".cub" }
$2 == "curacao" { zz=".cw"; zzz=".cuw" }
$2 == "cyprus" { zz=".cy"; zzz=".cyp" }
$2 == "czech\\ republic" { zz=".cz"; zzz=".cze" }
$2 == "czechia" { zz=".cz"; zzz=".cze" }
$2 == "democratic\\ republic\\ of\\ the\\ congo" { zz=".cd"; zzz=".cod" }
$2 == "denmark" { zz=".dk"; zzz=".dnk" }
$2 == "djibouti" { zz=".dj"; zzz=".dji" }
$2 == "dominican\\ republic" { zz=".do"; zzz=".dom" }
$2 == "dominica" { zz=".dm"; zzz=".dma" }
$2 == "ecuador" { zz=".ec"; zzz=".ecu" }
$2 == "egypt" { zz=".eg"; zzz=".egy" }
$2 == "el\\ salvador" { zz=".sv"; zzz=".slv" }
$2 == "equatorial\\ guinea" { zz=".gq"; zzz=".gnq" }
$2 == "eritrea" { zz=".er"; zzz=".eri" }
$2 == "estonia" { zz=".ee"; zzz=".est" }
$2 == "ethiopia" { zz=".et"; zzz=".eth" }
$2 == "falkland\\ islands" { zz=".fk"; zzz=".flk" }
$2 == "faroe\\ islands" { zz=".fo"; zzz=".fro" }
$2 == "fiji" { zz=".fj"; zzz=".fji" }
$2 == "finland" { zz=".fi"; zzz=".fin" }
$2 == "france" { zz=".fr"; zzz=".fra" }
$2 == "french\\ guiana" { zz=".gf"; zzz=".guf" }
$2 == "french\\ polynesia" { zz=".pf"; zzz=".pyf" }
$2 == "french\\ southern\\ territories" { zz=".tf"; zzz=".atf" }
$2 == "french\\ southern\\ and\\ antarctic\\ territories" { zz=".tf"; zzz=".atf" }
$2 == "gabon" { zz=".ga"; zzz=".gab" }
$2 == "gambia" { zz=".gm"; zzz=".gmb" }
$2 == "georgia" { zz=".ge"; zzz=".geo" }
$2 == "germany" { zz=".de"; zzz=".deu" }
$2 == "ghana" { zz=".gh"; zzz=".gha" }
$2 == "gibraltar" { zz=".gi"; zzz=".gib" }
$2 == "great\\ britain" { zz=".uk"; zzz=".gbr" }
$2 == "greece" { zz=".gr"; zzz=".grc" }
$2 == "greenland" { zz=".gl"; zzz=".grl" }
$2 == "grenada" { zz=".gd"; zzz=".grd" }
$2 == "guadeloupe" { zz=".gp"; zzz=".glp" }
$2 == "guam" { zz=".gu"; zzz=".gum" }
$2 == "guatemala" { zz=".gt"; zzz=".gtm" }
$2 == "guernsey" { zz=".gg"; zzz=".ggy" }
$2 == "guinea" { zz=".gn"; zzz=".gin" }
$2 == "guinea-bissau" { zz=".gw"; zzz=".gnb" }
$2 == "guyana" { zz=".gy"; zzz=".guy" }
$2 == "haiti" { zz=".ht"; zzz=".hti" }
$2 == "heard\\ island\\ and\\ mcdonald\\ islands" { zz=".hm"; zzz=".hmd" }
$2 == "herzegovina" { zz=".ba"; zzz="" }
$2 == "honduras" { zz=".hn"; zzz=".hnd" }
$2 == "hong\\ kong" { zz=".hk"; zzz=".hkg" }
$2 == "hungary" { zz=".hu"; zzz=".hun" }
$2 == "iceland" { zz=".is"; zzz=".isl" }
$2 == "india" { zz=".in"; zzz=".ind" }
$2 == "indonesia" { zz=".id"; zzz=".idn" }
$2 == "iran" { zz=".ir"; zzz=".irn" }
$2 == "iraq" { zz=".iq"; zzz=".irq" }
$2 == "ireland" { zz=".ie"; zzz=".irl" }
$2 == "isle\\ of\\ man" { zz=".im"; zzz=".imn" }
$2 == "israel" { zz=".il"; zzz=".isr" }
$2 == "italy" { zz=".it"; zzz=".ita" }
$2 == "jamaica" { zz=".jm"; zzz=".jam" }
$2 == "japan" { zz=".jp"; zzz=".jpn" }
$2 == "jersey" { zz=".je"; zzz=".jey" }
$2 == "jordan" { zz=".jo"; zzz=".jor" }
$2 == "kazakhstan" { zz=".kz"; zzz=".kaz" }
$2 == "kenya" { zz=".ke"; zzz=".ken" }
$2 == "kiribati" { zz=".ki"; zzz=".kir" }
$2 == "kuwait" { zz=".kw"; zzz=".kwt" }
$2 == "kyrgyzstan" { zz=".kg"; zzz=".kgz" }
$2 == "laos" { zz=".la"; zzz=".lao" }
$2 == "latvia" { zz=".lv"; zzz=".lva" }
$2 == "lebanon" { zz=".lb"; zzz=".lbn" }
$2 == "lesotho" { zz=".ls"; zzz=".lso" }
$2 == "liberia" { zz=".lr"; zzz=".lbr" }
$2 == "libya" { zz=".ly"; zzz=".lby" }
$2 == "liechtenstein" { zz=".li"; zzz=".lie" }
$2 == "lithuania" { zz=".lt"; zzz=".lyu" }
$2 == "luxembourg" { zz=".lu"; zzz=".lux" }
$2 == "macau" { zz=".mo"; zzz=".mac" }
$2 == "macao" { zz=".mo"; zzz=".mac" }
$2 == "macedonia" { zz=".mk"; zzz=".mkd" }
$2 == "madagascar" { zz=".mg"; zzz=".mdg" }
$2 == "malawi" { zz=".mw"; zzz=".mwi" }
$2 == "malaysia" { zz=".my"; zzz=".mys" }
$2 == "maldives" { zz=".mv"; zzz=".mdv" }
$2 == "mali" { zz=".ml"; zzz=".mli" }
$2 == "malta" { zz=".mt"; zzz=".mlt" }
$2 == "marshall\\ islands" { zz=".mh"; zzz=".mhl" }
$2 == "martinique" { zz=".mq"; zzz=".mtq" }
$2 == "mauritania" { zz=".mr"; zzz=".mrt" }
$2 == "mauritius" { zz=".mu"; zzz=".mus" }
$2 == "mayotte" { zz=".yt"; zzz=".myt" }
$2 == "mexico" { zz=".mx"; zzz=".mex" }
$2 == "micronesia" { zz=".fm"; zzz=".fsm" }
$2 == "moldova" { zz=".md"; zzz=".mda" }
$2 == "monaco" { zz=".mc"; zzz=".mco" }
$2 == "mongolia" { zz=".mn"; zzz=".mng" }
$2 == "montenegro" { zz=".me"; zzz=".mne" }
$2 == "montserrat" { zz=".ms"; zzz=".msr" }
$2 == "morocco" { zz=".ma"; zzz=".mar" }
$2 == "mozambique" { zz=".mz"; zzz=".moz" }
$2 == "myanmar" { zz=".mm"; zzz=".mmr" }
$2 == "namibia" { zz=".na"; zzz=".nam" }
$2 == "nauru" { zz=".nr"; zzz=".nru" }
$2 == "nepal" { zz=".np"; zzz=".npl" }
$2 == "netherlands\\ antilles" { zz=".an"; zzz=".ant" }
$2 == "netherlands" { zz=".nl"; zzz=".nld" }
$2 == "nevis\\ and\\ st\\ kitts" { zz=".kn"; zzz=".kna" }
$2 == "new\\ caledonia" { zz=".nc"; zzz=".ncl" }
$2 == "new\\ zealand" { zz=".nz"; zzz=".nzl" }
$2 == "nicaragua" { zz=".ni"; zzz=".nic" }
$2 == "niger" { zz=".ne"; zzz=".ner" }
$2 == "nigeria" { zz=".ng"; zzz=".nga" }
$2 == "niue" { zz=".nu"; zzz=".niu" }
$2 == "norfolk\\ island" { zz=".nf"; zzz=".nfk" }
$2 == "north\\ korea" { zz=".kp"; zzz=".prk" }
$2 == "northern\\ mariana\\ islands" { zz=".mp"; zzz=".mnp" }
$2 == "norway" { zz=".no"; zzz=".nor" }
$2 == "oman" { zz=".om"; zzz=".omn" }
$2 == "pakistan" { zz=".pk"; zzz=".pak" }
$2 == "palau" { zz=".pw"; zzz=".plw" }
$2 == "palestine" { zz=".ps"; zzz=".pse" }
$2 == "panama" { zz=".pa"; zzz=".pan" }
$2 == "papua\\ new\\ guinea" { zz=".pg"; zzz=".png" }
$2 == "paraguay" { zz=".py"; zzz=".pry" }
$2 == "peru" { zz=".pe"; zzz=".per" }
$2 == "philippines" { zz=".ph"; zzz=".phl" }
$2 == "pitcairn\\ islands" { zz=".pn"; zzz=".pcn" }
$2 == "pitcairn" { zz=".pn"; zzz=".pcn" }
$2 == "poland" { zz=".pl"; zzz=".pol" }
$2 == "portugal" { zz=".pt"; zzz=".prt" }
$2 == "puerto\\ rico" { zz=".pr"; zzz=".pri" }
$2 == "qatar" { zz=".qa"; zzz=".qat" }
$2 == "reunion" { zz=".re"; zzz=".reu" }
$2 == "romania" { zz=".ro"; zzz=".rom" }
$2 == "russia" { zz=".ru"; zzz=".rus" }
$2 == "rwanda" { zz=".rw"; zzz=".rwa" }
$2 == "saba" { zz=".bq"; zzz=".bes" }
$2 == "saint\\ barthelemy" { zz=".bl"; zzz=".blm" }
$2 == "saint\\ helena" { zz=".sh"; zzz=".shn" }
$2 == "saint\\ kitts\\ and\\ nevis" { zz=".kn"; zzz=".kna" }
$2 == "saint\\ lucia" { zz=".lc"; zzz=".lca" }
$2 == "saint\\ martin" { zz=".mf"; zzz=".maf" }
$2 == "saint\\ pierre\\ and\\ miquelon" { zz=".pm"; zzz=".spm" }
$2 == "saint\\ vincent\\ and\\ the\\ grenadines" { zz=".vc"; zzz=".vct" }
$2 == "samoa" { zz=".ws"; zzz=".wsm" }
$2 == "san\\ marino" { zz=".sm"; zzz=".smr" }
$2 == "sao\\ tome\\ and\\ principe" { zz=".st"; zzz=".stp" }
$2 == "sark" { zz=".gg"; zzz="" }
$2 == "saudi\\ arabia" { zz=".sa"; zzz=".sau" }
$2 == "senegal" { zz=".sn"; zzz=".sen" }
$2 == "serbia" { zz=".rs"; zzz=".srb" }
$2 == "serbia\\ and\\ montenegro" { zz=".cs"; zzz=".yug" }
$2 == "seychelles" { zz=".sc"; zzz=".syc" }
$2 == "sierra\\ leone" { zz=".sl"; zzz=".sle" }
$2 == "singapore" { zz=".sg"; zzz=".sgp" }
$2 == "sint\\ maarten" { zz=".mf"; zzz=".maf" }
$2 == "slovakia" { zz=".sk"; zzz=".svk" }
$2 == "slovenia" { zz=".si"; zzz=".svn" }
$2 == "solomon\\ islands" { zz=".sb"; zzz=".slb" }
$2 == "somalia" { zz=".so"; zzz=".som" }
$2 == "south\\ africa" { zz=".za"; zzz=".zaf" }
$2 == "south\\ georgia\\ and\\ sandwich\\ islands" { zz=".gs"; zzz=".sgs" }
$2 == "south\\ georgia\\ and\\ the\\ south\\ sandwich\\ islands" { zz=".gs"; zzz=".sgs" }
$2 == "south\\ korea" { zz=".kr"; zzz=".kor" }
$2 == "south\\ sudan" { zz=".ss"; zzz=".ssd" }
$2 == "spain" { zz=".es"; zzz=".esp" }
$2 == "sri\\ lanka" { zz=".lk"; zzz=".lka" }
$2 == "st\\ eustatius" { zz=".bq"; zzz=".bes" }
$2 == "st\\ barthelemy" { zz=".bl"; zzz="" }
$2 == "st\\ kitts" { zz=".kn"; zzz=".kna" }
$2 == "st\\ pierre\\ miquelon" { zz=".pm"; zzz=".spm" }
$2 == "st\\ pierre\\ and\\ miquelon" { zz=".pm"; zzz=".spm" }
$2 == "st.\\ martin" { zz=".mf"; zzz=".maf" }
$2 == "sudan" { zz=".sd"; zzz=".sdn" }
$2 == "suriname" { zz=".sr"; zzz=".sur" }
$2 == "svalbard\\ and\\ jan\\ mayen" { zz=".sj"; zzz=".sjm" }
$2 == "svalbard\\ and\\ jan\\ mayen\\ islands" { zz=".sj"; zzz=".sjm" }
$2 == "sverige" { zz=".se"; zzz=".swe" }
$2 == "swaziland" { zz=".sz"; zzz=".swz" }
$2 == "sweden" { zz=".se"; zzz=".swe" }
$2 == "switzerland" { zz=".ch"; zzz=".che" }
$2 == "syria" { zz=".sy"; zzz=".syr" }
$2 == "taiwan" { zz=".tw"; zzz=".twn" }
$2 == "tajikistan" { zz=".tj"; zzz=".tjk" }
$2 == "tanzania" { zz=".tz"; zzz=".tza" }
$2 == "thailand" { zz=".th"; zzz=".tha" }
$2 == "timor-leste" { zz=".tl"; zzz=".tls" }
$2 == "togo" { zz=".tg"; zzz=".tgo" }
$2 == "tokelau" { zz=".tk"; zzz=".tkl" }
$2 == "tonga" { zz=".to"; zzz=".ton" }
$2 == "trinidad\\ and\\ tobago" { zz=".tt"; zzz=".tto" }
$2 == "tunisia" { zz=".tn"; zzz=".tun" }
$2 == "turkey" { zz=".tr"; zzz=".tur" }
$2 == "turkmenistan" { zz=".tm"; zzz=".tkm" }
$2 == "turks\\ and\\ caicos\\ islands" { zz=".tc"; zzz=".tca" }
$2 == "tuvalu" { zz=".tv"; zzz=".tuv" }
$2 == "uganda" { zz=".ug"; zzz=".uga" }
$2 == "ukraine" { zz=".ua"; zzz=".ukr" }
$2 == "united\\ arab\\ emirates" { zz=".ae"; zzz=".are" }
$2 == "united\\ kingdom" { zz=".uk"; zzz=".gbr" }
$2 == "united\\ states" { zz=".us"; zzz=".usa" }
$2 == "uruguay" { zz=".uy"; zzz=".ury" }
$2 == "us\\ minor\\ outlying\\ islands" { zz=".um"; zzz=".umi" }
$2 == "us\\ virgin\\ islands" { zz=".vi"; zzz=".vir" }
$2 == "uzbekistan" { zz=".uz"; zzz=".uzb" }
$2 == "vanuatu" { zz=".vu"; zzz=".vut" }
$2 == "vatican\\ city\\ state" { zz=".va"; zzz=".vat" }
$2 == "venezuela" { zz=".ve"; zzz=".ven" }
$2 == "vietnam" { zz=".vn"; zzz=".vnm" }
$2 == "wallis\\ and\\ futuna\\ islands" { zz=".wf"; zzz=".wlf" }
$2 == "western\\ somoa" { zz=".ws"; zzz="" }
$2 == "western\\ sahara" { zz=".eh"; zzz=".esh" }
$2 == "yemen" { zz=".ye"; zzz=".yem" }
$2 == "zaire" { zz=".cd"; zzz=".cod" }
$2 == "zambia" { zz=".zm"; zzz=".zmb" }
$2 == "zimbabwe" { zz=".zw"; zzz=".zwe" }
$2 == "zuid\\ afrika" { zz=".za"; zzz="" }
{ printf "%s\t%s\t%s\t%s\n", $1, zz, zzz, $2; zz=""; zzz="" }
BEGIN {
    print "# DO NOT EDIT!!! Produced by geo-cs-html2db"
}
' \
    > countries.db

sed < $REPLY \
    -e '1,/"ctl00_ContentBody_lbStates/d' \
    -e '/<.select>/,$d' \
    -e 's/.*<option.* value="//g' \
    -e 's/ *<.option>.*//g' \
    -e 's/ (.*)//g' \
    -e 's/ /\\ /g' \
    -e 's/&#225;/a/g' \
    -e 's/&#237;/i/g' \
    -e 's/&#243;/o/g' \
    -e 's/&#233;/e/g' \
    -e 's/&#231;/c/g' \
    -e 's/&#252;/u/g' \
    -e 's/&#253;/y/g' \
    -e 's/&#241;/n/g' \
    -e 's/&#201;/E/g' \
    -e 's/&#228;/a/g' \
    -e 's/&#246;/o/g' \
    -e 's/&#232;/e/g' \
    -e 's/&#227;/a/g' \
    -e 's/&#248;/o/g' \
    -e 's/&#214;/O/g' \
    -e 's/&#216;/O/g' \
    -e 's/&#244;/o/g' \
    -e 's/&#250;/u/g' \
    -e 's/&#229;/a/g' \
    -e 's/&#206;/i/g' \
    -e 's/&#8211;/-/g' \
    -e "s/&#39;/'/g" \
    -e 's/\xc5\xbd/Z/g' \
    -e 's/\xc5\x9b/s/g' \
    -e 's/\xc5\x9a/S/g' \
    -e 's/\xc5\x81/L/g' \
    -e 's/\xc5\x82/l/g' \
    -e 's/\xc5\x84/n/g' \
    -e 's/\xc5\x88/n/g' \
    -e 's/\xc5\x99/r/g' \
    -e 's/\xc5\xa1/s/g' \
    -e 's/\xc4\x8d/c/g' \
    -e 's/\xc4\x85/a/g' \
    -e 's/\xc4\x99/e/g' \
    -e 's/\xc4\x9b/e/g' \
    -e 's/\xc3\x89/E/g' \
    -e 's/\xc3\x8e/I/g' \
    -e 's/\xc3\x96/O/g' \
    -e 's/\xc3\x98/O/g' \
    -e 's/\xc3\x9a/U/g' \
    -e 's/\xc3\xa1/a/g' \
    -e 's/\xc3\xa2/a/g' \
    -e 's/\xc3\xa3/a/g' \
    -e 's/\xc3\xa4/a/g' \
    -e 's/\xc3\xa5/a/g' \
    -e 's/\xc3\xa7/c/g' \
    -e 's/\xc3\xa8/e/g' \
    -e 's/\xc3\xa9/e/g' \
    -e 's/\xc3\xad/o/g' \
    -e 's/\xc3\xb1/n/g' \
    -e 's/\xc3\xb3/o/g' \
    -e 's/\xc3\xb4/o/g' \
    -e 's/\xc3\xb6/o/g' \
    -e 's/\xc3\xb8/o/g' \
    -e 's/\xc3\xba/u/g' \
    -e 's/\xc3\xbc/u/g' \
    -e 's/\xc3\xbd/y/g' \
    -e 's/\xe2\x80\x93/-/g' \
    -e 's/">/\t/g' \
    -e '/^\r$/,$d'\
| tr [A-Z] [a-z] \
| awk -F '	' '
$2 == "alabama" { zz="al" }
$2 == "alaska" { zz="ak" }
$2 == "arizona" { zz="az" }
$2 == "arkansas" { zz="as" }
$2 == "california" { zz="ca" }
$2 == "colorado" { zz="co" }
$2 == "connecticut" { zz="ct" }
$2 == "district\\ of\\ columbia" { zz="dc" }
$2 == "delaware" { zz="de" }
$2 == "florida" { zz="fl" }
$2 == "georgia" { zz="ga" }
$2 == "hawaii" { zz="ha" }
$2 == "idaho" { zz="id" }
$2 == "illinois" { zz="il" }
$2 == "indiana" { zz="in" }
$2 == "iowa" { zz="ia" }
$2 == "kansas" { zz="ks" }
$2 == "kentucky" { zz="ky" }
$2 == "louisiana" { zz="la" }
$2 == "maine" { zz="me" }
$2 == "maryland" { zz="md" }
$2 == "massachusetts" { zz="md" }
$2 == "michigan" { zz="mi" }
$2 == "minnesota" { zz="mn" }
$2 == "mississippi" { zz="ms" }
$2 == "missouri" { zz="mo" }
$2 == "montana" { zz="mt" }
$2 == "nebraska" { zz="ne" }
$2 == "nevada" { zz="nv" }
$2 == "new\\ hampshire" { zz="nh" }
$2 == "new\\ jersey" { zz="nj" }
$2 == "new\\ mexico" { zz="nm" }
$2 == "new\\ york" { zz="ny" }
$2 == "north\\ carolina" { zz="nc" }
$2 == "north\\ dakota" { zz="nd" }
$2 == "ohio" { zz="oh" }
$2 == "oklahoma" { zz="ok" }
$2 == "oregon" { zz="or" }
$2 == "pennsylvania" { zz="pa" }
$2 == "rhode\\ island" { zz="ri" }
$2 == "south\\ carolina" { zz="sc" }
$2 == "south\\ dakota" { zz="sd" }
$2 == "tennessee" { zz="tn" }
$2 == "texas" { zz="tx" }
$2 == "utah" { zz="ut" }
$2 == "vermont" { zz="vt" }
$2 == "virginia" { zz="va" }
$2 == "washington" { zz="wa" }
$2 == "west\\ virginia" { zz="wv" }
$2 == "wisconsin" { zz="wi" }
$2 == "wyoming" { zz="wy" }
{ printf "%s\t%s\t%s\n", $1, zz, $2; zz="" }
BEGIN {
    print "# DO NOT EDIT!!! Produced by geo-cs-html2db"
}
' \
    > states.db

chmod 444 countries.db states.db
