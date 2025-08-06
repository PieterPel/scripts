#!/bin/bash
# Alireza Shafaei - shafaei@cs.ubc.ca - Jan 2016
# Adjusted by: Pieter Pel - pelpieter@gmail.com - Aug 2025

resolution=1024
density=300
colorspace="-colorspace sRGB -background white -alpha remove"
makeLandscape=false
makeWidescreen=false

if [ $# -eq 0 ]; then
    echo "No arguments supplied!"
    echo "Usage: ./pdf2pptx.sh file.pdf"
    echo "			Generates file.pdf.pptx in A4 portrait format (by default)"
    echo "       ./pdf2pptx.sh file.pdf landscape"
    echo "			Generates file.pdf.pptx in A4 landscape format"
    exit 1
fi

if [ $# -eq 2 ]; then
	if [ "$2" == "landscape" ]; then
		makeLandscape=true
    elif [ "$2" == "widescreen" ]; then
        makeWidescreen=true
	fi
fi

echo "Doing $1"
tempname="$1.temp"
if [ -d "$tempname" ]; then
	echo "Removing ${tempname}"
	rm -rf "$tempname"
fi

mkdir "$tempname"

# Set return code of piped command to first nonzero return code
set -o pipefail
n_pages=$(identify "$1" | wc -l)
returncode=$?
if [ $returncode -ne 0 ]; then
   echo "Unable to count number of PDF pages, exiting"
   exit $returncode
fi
if [ $n_pages -eq 0 ]; then
   echo "Empty PDF (0 pages), exiting"
   exit 1
fi

# for ((i=0; i<n_pages; i++))
for ((i=0; i<3; i++))
do
   magick convert -density $density $colorspace -resize "x${resolution}" "$1[$i]" "$tempname"/slide-$i.png
   returncode=$?
    if [ $returncode -ne 0 ]; then break; fi
done

for img in "$tempname"/slide-*.png; do
    if $makeLandscape; then
        # Resize to A4 landscape: 3508x2480
        magick "$img" -resize 3508x2480\! "$img"
    elif $makeWidescreen; then
        # Resize to widescreen: 1920x1080 (without distortion)
        magick "$img" -resize 1920x1080 -gravity center -background white -extent 1920x1080 "$img"
    else
        # Resize to A4 portrait: 2480x3508
        magick "$img" -resize 2480x3508\! "$img"
    fi
done


if [ $returncode -eq 0 ]; then
	echo "Extraction succ!"
else
	echo "Error with extraction"
	exit $returncode
fi

if (which perl > /dev/null); then
	# https://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac#comment47931362_1115074
	mypath=$(perl -MCwd=abs_path -le '$file=shift; print abs_path -l $file? readlink($file): $file;' "$0")
elif (which python > /dev/null); then
	# https://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac#comment42284854_1115074
	mypath=$(python -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))' "$0")
elif (which ruby > /dev/null); then
	mypath=$(ruby -e 'puts File.realpath(ARGV[0])' "$0")
else
	mypath="$0"
fi
mydir=$(dirname "$mypath")

pptname="$1.pptx.base"
fout=$(basename "$1" .pdf)".pptx"
rm -rf "$pptname"
cp -r "$mydir"/template "$pptname"

mkdir "$pptname"/ppt/media

cp "$tempname"/*.png "$pptname/ppt/media/"

function call_sed {
	if [ "$(uname -s)" == "Darwin" ]; then
		sed -i "" "$@"
	else
		sed -i "$@"
	fi
}

function add_slide {
	pat='slide1\.xml\"\/>'
	id=$1
	id=$((id+8))
	entry='<Relationship Id=\"rId'$id'\" Type=\"http:\/\/schemas\.openxmlformats\.org\/officeDocument\/2006\/relationships\/slide\" Target=\"slides\/slide-'$1'\.xml"\/>'
	rep="${pat}${entry}"
	call_sed "s/${pat}/${rep}/g" ../_rels/presentation.xml.rels

	pat='slide1\.xml\" ContentType=\"application\/vnd\.openxmlformats-officedocument\.presentationml\.slide+xml\"\/>'
	entry='<Override PartName=\"\/ppt\/slides\/slide-'$1'\.xml\" ContentType=\"application\/vnd\.openxmlformats-officedocument\.presentationml\.slide+xml\"\/>'
	rep="${pat}${entry}"
	call_sed "s/${pat}/${rep}/g" ../../\[Content_Types\].xml

	sid=$1
	sid=$((sid+256))
	pat='<p:sldIdLst>'
	entry='<p:sldId id=\"'$sid'\" r:id=\"rId'$id'\"\/>'
	rep="${pat}${entry}"
	call_sed "s/${pat}/${rep}/g" ../presentation.xml
}

function make_slide {
	cp ../slides/slide1.xml ../slides/slide-$1.xml
	cat ../slides/_rels/slide1.xml.rels | sed "s/image1\.JPG/slide-${slide}.png/g" > ../slides/_rels/slide-$1.xml.rels
	add_slide $1
}

pushd "$pptname"/ppt/media/
count=`ls -ltr | wc -l`
for (( slide=$count-2; slide>=0; slide-- ))
do
	echo "Processing "$slide
	make_slide $slide
done

if [ "$makeLandscape" = true ]; then
    # Set slide size to A4 landscape
    pat='<p:sldSz cx=\"9144000\" cy=\"6858000\" type=\"screen4x3\"\/>'
    a4landscape='<p:sldSz cx=\"11232000\" cy=\"7938000\" type=\"A4\"\/>'
    call_sed "s/${pat}/${a4landscape}/g" ../presentation.xml

elif [ "$makeWidescreen" = true ]; then
    # Set slide size to widescreen
    pat='<p:sldSz cx=\"9144000\" cy=\"6858000\" type=\"screen4x3\"\/>'
    widescreen='<p:sldSz cx=\"12192000\" cy=\"6858000\" type=\"screen16x9\"\/>'
    call_sed "s/${pat}/${widescreen}/g" ../presentation.xml

else
    # Set slide size to A4 portrait
    pat='<p:sldSz cx=\"9144000\" cy=\"6858000\" type=\"screen4x3\"\/>'
    a4portrait='<p:sldSz cx=\"7938000\" cy=\"11232000\" type=\"A4\"\/>'
    call_sed "s/${pat}/${a4portrait}/g" ../presentation.xml
fi
popd

pushd "$pptname"
rm -rf ../"$fout"
zip -q -r ../"$fout" .
popd

rm -rf "$pptname"
rm -rf "$tempname"
