#!/bin/bash

######################################################################################################
##
## Examples: 
## 		$ ./vidmerge.sh .
##		$ ./vidmerge.sh ./Test
##
## REFERENCE: Go to https://trac.ffmpeg.org/wiki/Concatenate and section "Using intermediate files"
##
######################################################################################################

if [[ ! -d $1 ]]; then
	echo "[ERR] Video location is not provided or does not exit!"
	exit 1
fi
echo "[WARN] This script will replace spaces with underscores in the names of the original videos."

concat=""

cd $1 && echo "[DEB] Changed directory to $1"

for srcfile in $(find . -maxdepth 1 -type f -name "*.mp4" -printf "%P\n" | sort -V); do
	## Remove spaces from the names of source videos 
	## to avoid error when running ffmpeg command
	newname=$( echo "$srcfile" | tr " " "_" )
	mv "$srcfile" "$newname"
	
	
	ffmpeg -i $newname -c copy -bsf:v h264_mp4toannexb "$newname.ts"
	
	concat+="$newname.ts|"
done

## Start merging here
outputname="mergedvideos-$(date +%s).mp4"
ffmpeg -i "concat:$concat" -c copy -bsf:a aac_adtstoasc "$outputname"

rm *.mp4.ts

