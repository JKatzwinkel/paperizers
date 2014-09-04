#!/bin/bash

# checkout latest whatif posting
wget http://whatif.xkcd.com -q -O - \
	| sed -n '/\s*<article class=.entry.>/,/\s*<\/article>/p' \
	> out.tex
# extract resource identifier
url=$(grep "\s*<a href.*><h1>" out.tex | grep -o "what-if\.xkcd\.com\/[0-9]*\/")
#echo $url

if [ -z "$url" ]; then
	#echo "no link found"
	exit
fi
# check if url is known already
dir="$HOME/.paperizers"
if [ ! -d "$dir" ]; then
	mkdir -p $dir
fi
urlfile="$dir/urls.txt"
if [ ! -e "$urlfile" ]; then
	#echo "create file urls.txt"
	touch $urlfile
fi
if [ -n "$(grep $url $urlfile)" ]; then
	#echo "no new entries. .."
	exit
fi
# create image directory, if needed
if [ ! -d "$dir/xkcd" ]; then
  mkdir -p "$dir/xkcd"
fi
# download images
while read src; do
  # create issue image directory from image link locators
  imdir=$(echo $src | sed -n 's/\(.\+\/\).*$/\1/gp')
  if [ ! -d "$dir/xkcd$imdir" ]; then
    mkdir -p "$dir/xkcd$imdir"
  fi
  wget "http://whatif.xkcd.com$src" -O $dir/xkcd$src
done < <(sed -n 's/<img .* src=\"\([^ ]*\)\">/\1/p' out.tex)

## html conversion:
# remove article tags, replace h1 
sed -i 's/<\/*article[^<>]*>//g; s/<h1>\(.*\)<\/h1>/\\section*{\1}/g' out.tex
# resolve html special char escapables
sed -i "s/&#39;/'/g; s/&quot;/\"/g; s/&#8226;//g; s/&gt;/\\\\textgreater/g; s/&lt;/\\\\textless/g" out.tex
sed -i 's/®/\\textregistered/g; s/©/\\textcopyright/g; s/™/\\texttrademark/g' out.tex 
# resolve painful latex pitfall characters:
sed -i 's/#/\\#/g; s/—/ --- /g; s/%/\\%/g; s_\([^\]\)\$_\1\\$_g' out.tex
# br tags
sed -i 's/<br \/>/\\\\/g' out.tex
# em tags
perl -pi.bck -e 's/<em>(.*?)<\/em>/\\textit{\1}/g' out.tex
# strong tags
perl -pi.bck -e 's/<strong>(.*?)<\/strong>/\\textbf{\1}/g' out.tex
# strike tags
perl -pi.bck -e 's/<strike>(.*?)<\/strike>/\\sout{\1}/g' out.tex
# blockquotes
perl -pi.bck -e 's/<blockquote>(.*?)<\/blockquote>/\\begin{quote}\1\\end{quote}/g' out.tex
# sub tags
sed -i 's/<sub>\([^<]*\)<\/sub>/\\textsubscript{\1}/g' out.tex
# sup tags
sed -i 's/<sup>\([^<]*\)<\/sup>/\\textsuperscript{\1}/g' out.tex
# p tags
sed -i 's/<p id=.question.>\(.*\)<\/p>/\\begin{abstract}\1\\end{abstract}/g; s/<p id=.attribute.>\(.*\)<\/p>/\\begin{flushright}\1\\end{flushright}\n/g' out.tex
sed -i 's/<p>//g; s/<\/p>/\\\\\n/g;' out.tex
# ref tags # insert linebreaks at ref tags
sed -i 's/\(<span class=.ref.><span class=.refnum.>\)/\n\1/g' out.tex
sed -i 's/<span class=.ref.><span class=.refnum.>[^<]*<\/span><span class=.refbody.>\(.*\)<\/span><\/span>/\\footnote{\1}/g' out.tex
# a tags [multiple times in case theres multiple links in one line]
for i in 1 2 3 4 5; do
  sed -i 's/\(.*\)<a href=.\([^ ]*\)\">\(.*\)<\/a>/\1\3\\textsuperscript{\\url{\2}}/g' out.tex
done
#perl -pi.bck -e 's_([fhtps]{3,5}:\/\/[^/]*\.\w+)(\/\S*)_\1\-\2/g'
# insert spaces between domain and path in urls to force linebreaks (doesnt work in url element apparently)
sed -i 's/\([htf]\+ps\?:\/\/\(\S\+\.\)\+\w\{2,4\}\/\)\([^/]\+\)/\1 \3/g' out.tex
# lists
sed -i 's/<ul>/\\begin{itemize}/g; s/<\/ul>/\\end{itemize}/g; s/<li>\(.*\)<\/li>/\\item \1/g' out.tex
# img tags
sed -i 's#<img .* title=.\(.*\)\" src=\"\([^ ]*\)\">#\\begin{center}\\includegraphics[width=3.7cm]\{'${dir}/xkcd'\2\}\\footnote{\1}\\end{center}\n#g' out.tex

today=$(date +%y%m%d)
outfile="$dir/whatif$today"
#echo "saving to $outfile.{tex,pdf}"

echo '''
\documentclass{article}
\usepackage{graphicx}
\usepackage{fixltx2e}
\usepackage[colorlinks=true,linkcolor=black,urlcolor=black]{hyperref}
\usepackage[normalem]{ulem}
\usepackage{textcomp}
\begin{document}
''' > "$outfile.tex"
cat out.tex >> "$outfile.tex"
echo '\end{document}' >> "$outfile.tex"

pdflatex -interaction batchmode -output-directory $dir $outfile.tex
lpr "$outfile.pdf"
# if evth went fine, save url as known
if [ "$?" -eq 0 ]; then
  echo "$today $url" >> $urlfile
fi
