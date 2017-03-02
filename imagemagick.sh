#!/bin/bash
shopt -s nullglob
shopt -s globstar
resolution=""
global_dir=""
newformat=""
files=()
newfiles=()
total_size=0
reset=`tput sgr0`
blue=`tput setaf 4`
green=`tput setaf 2`
bytesToHuman() {
    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}
if [ $# == 0 ]; then
    echo "Image Manipulation Script"
    echo "Written by Johan Larsson"
    echo
    echo "Usage"
    echo " -d - Specifies target directory"
    echo "    - Example: imagemagick.sh -d mydirectory/"
    echo " -e - File in directory that you want to remain untouched"
    echo "    - Example: imagemagick.sh -d mydirectory/ -e mydirectory/myfile.jpg"
    echo " -f - Specifies format to convert files into"
    echo "    - Example: imagemagick.sh -d mydirectory/ -f .png"
    echo " -r - Specifies resolution to convert files into"
    echo "    - Example: imagemagick.sh -d mydirectory/ -r 100x100"
    exit 1
fi
while getopts ":d:e:f:r:" opt; do
    case $opt in
        d)
            dir="$OPTARG"
            filelist="$(ls $dir)"
            dirname="$(readlink -f $dir)"
            dirlist="$(ls $dirname)"
            global_dir=$dirname
            counter=0
            for i in $dirlist; do
                files+=("$dirname/$i")
            done
            ;;
        e)
            temp="$OPTARG"
            temp="$(readlink -f $temp)"
            dirlist="$(ls $global_dir)"
            for i in $dirlist; do
            	if [[ "$global_dir/$i" != "$temp" ]]; then
            		newfiles+=("$global_dir/$i")
            	fi
            done
            files=$newfiles
            ;;
        f)
            newformat=$OPTARG
            ;;
        r)
            resolution=$OPTARG
            ;;
        \?)
            echo "invalid option: -$OPTARG" >&2
            ;;
    esac
done
for i in "${files[@]}"; do
    oldsize=$(ls -l $i | awk '{print $5}')
    convert -resize $resolution $i $i
    newsize=$(ls -l $i | awk '{print $5}')
    saved=$(expr $oldsize - $newsize)
    total_size=$(expr $total_size + $saved)
    echo "Converting ${blue}${i##*/}${reset}"
    echo -e "Previous size: `bytesToHuman $oldsize`\tNew size: ${green}`bytesToHuman $newsize`${reset}\tSaved space: `bytesToHuman $saved`"
done
for i in "${files[@]}"; do
	if [[ "$i" != *"$newformat" ]]; then
		newextension=${i##*.}
		newfile="${i%.*}${newformat,,}"
		echo "Converting ${blue}${i##*/}${reset} into ${blue}${newfile##*/}${reset}"
		convert $i $newfile
		rm $i
	fi
done
echo "Total saved: ${green}`bytesToHuman $total_size`${reset}"