#!/bin/bash

# extract url from rss feed
#echo "retrieve.."
url=$(wget http://www.titanic-magazin.de/ich.war.bei.der.waffen.rss -q -O - \
	| grep -A 4 "<title>Gärtners kritisches Sonntags" \
	| sed -n 's/\s*<link>\([^<]*\)<.*/\1/gp')

if [ -z "$url" ]; then
#	echo "no link found"
	exit
fi
# check if url is known already
dir="$HOME/.paperizers"
if [ ! -d "$dir" ]; then
	mkdir -p $dir
fi
urlfile="$dir/urls.txt"
if [ ! -e "$urlfile" ]; then
#	echo "create file urls.txt"
	touch $urlfile
fi
if [ -n "$(grep $url $urlfile)" ]; then
#	echo "no new entries. quit.."
	exit
fi

today=$(date +%y%m%d)
outfile="$dir/gaertner$today"
echo "saving to $outfile.{html,pdf}"

echo "$today $url" >> $urlfile

echo """
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!DOCTYPE html
     PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
     \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xml:lang=\"en\" lang=\"en\" xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
	<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
</head>
<body>
	<div style=\"font-size:6px\">""" > "$outfile.html"

wget $url -q -O - \
	| sed -n 's/.*class=.tt_news-date.*\(05.01.2014\).*/\1: /p
	s/.*\(Gärtners kritisches Sonntagsfrühstück\):\([^<]*\)<\/div.*/<b>\1<\/b><h4>\2<\/h4>/p
	/<div class=.tt_news-bodytext/,/.*tt_news-prevnextarticlelinks.*/ { 
		/<p class/,/^\s*$/ {p}
	}' \
	| sed 's/<img[^>]*>//g' \
	| sed 's/ä/\&auml;/g' \
	| sed 's/Ä/\&Auml;/g' \
	| sed 's/ö/\&ouml;/g' \
	| sed 's/Ö/\&Ouml;/g' \
	| sed 's/ü/\&uuml;/g' \
	| sed 's/Ü/\&Uuml;/g' \
	| sed 's/„/\&raquo;/g' \
	| sed 's/“/\&laquo;/g' \
	| sed 's/é/\&eacute;/g' \
	| sed 's/è/\&egrave;/g' \
	| sed 's/…/\&#8230;/g' \
	| sed 's/‘/\&#8217;/g' \
	| sed 's/–/\&#8212;/g' \
	| sed 's/ß/\&szlig;/g' >> "$outfile.html"


echo "</body></html>" >> "$outfile.html"

#html2ps -o out.ps -e UTF-8 out.html 
#html2ps -o out.ps out.html 
htmldoc -t pdf -f "$outfile.pdf" --size a4 --textfont times --webpage "$outfile.html"
lpr "$outfile.pdf"

