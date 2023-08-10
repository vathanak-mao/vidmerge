#!/bin/bash

if [[ ! -d $1 ]]; then
	echo "[ERR] Video location is not provided or does not exit!"
	exit 1
fi

cd "$1" && echo "[DEB] Changed directory to $1"

concat=""
newnames=()
for srcfile in *.mp4; do
	echo "[DEB] srcfile: $srcfile"
	
	## Remove spaces from the names of source videos 
	## to avoid error when running ffmpeg command
	newname=$( echo "$srcfile" | tr " " "_" )
	mv "$srcfile" "$newname" && newnames+=("$newname")
	
	## Go to https://trac.ffmpeg.org/wiki/Concatenate then section "Using intermediate files"
	ffmpeg -i $newname -c copy -bsf:v h264_mp4toannexb "$newname.ts"
	
	concat+="$newname.ts|"
	
	newnames+=("$newname")
done

## Start merging videos here
outputname="mergedvideos-$(date +%s).mp4"
ffmpeg -i "concat:$concat" -c copy -bsf:a aac_adtstoasc "$outputname"

## Rename the source videos back to their original ones
echo "[DEB] newnames: ${newnames[@]}"
for newname in ${newnames[@]}; do 
	originalname=$(echo $newname | tr "_" " ")
	mv "$newname" "$originalname"
done

## Remove intermeditate files
rm *.mp4.ts

