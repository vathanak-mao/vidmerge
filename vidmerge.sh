#!/bin/bash

if [[ ! -d $1 ]]; then
	echo "[ERR] Video location is not provided or does not exit!"
	exit 1
fi

cd "$1" && echo "[DEB] Changed directory to $1"

#filenames=$(find . -mindepth 1 -maxdepth 1 -type f -name '*.mp4' -printf '%P\n' | sort -V | tr "\n" ":")
filenames=$(ls -1rt | sed 's/^"//g;s/"$//g' | tr "\n" ":") 
echo "[DEB] filenames: $filenames"

IFS=":" read -a srcfiles <<< "$filenames" 

concat=""
newnames=()
for srcfile in "${srcfiles[@]}"; do
	echo "[DEB] srcfile: $srcfile"
	
	## Remove spaces from the names of source videos 
	## to avoid error when running ffmpeg command
	tmpname=$( echo "$srcfile" | tr " " "_" )
	mv "$srcfile" "$tmpname" && newnames+=("$tmpname")
	
	## Go to https://trac.ffmpeg.org/wiki/Concatenate then section "Using intermediate files"
	## For "-c:v" option, go to https://ffmpeg.org/ffmpeg.html#Stream-selection
	ffmpeg -i $tmpname -c:v copy -bsf:v h264_mp4toannexb "$tmpname.ts"
	
	concat+="$tmpname.ts|"
	
	#newnames+=("$tmpname")
done

## Start merging videos here
outputname="mergedvideos-$(date +%s).mp4"
ffmpeg -i "concat:$concat" -c:v copy -bsf:a aac_adtstoasc "$outputname"

## Rename the source videos back to their original ones
echo "[DEB] newnames: ${newnames[@]}"
for newname in ${newnames[@]}; do 
	originalname=$(echo $newname | tr "_" " ")
	mv "$newname" "$originalname"
done

## Remove intermeditate files
rm *.mp4.ts

