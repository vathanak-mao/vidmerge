#!/bin/bash

if [[ ! -d $1 ]]; then
	echo "[ERR] Video location is not provided or does not exit!"
	exit 1
fi

cd "$1" && echo "[DEB] Changed directory to $1"

#filenames=$(find . -mindepth 1 -maxdepth 1 -type f -name '*.mp4' -printf '%P\n' | sort -V | tr "\n" ":")

filenames=$(ls -1rt *.mp4 | sed 's/^"//g;s/"$//g' | tr "\n" ":") 
## Any filenames containing a space are enclosed with single quote so the 'sed' command will remove them

echo "[DEB] filenames: $filenames"

IFS=":" read -a srcfiles <<< "$filenames" 


## ----------------------------------------------------------------

concat=""
newnames=()
tmpfilenames=()

for srcfile in "${srcfiles[@]}"; do
	echo "[DEB] srcfile: $srcfile"
	
	tmp=$srcfile
	
	## if contains spacial characters, make a copy with a new name
	if [[ "$srcfile" =~ [^a-zA-Z0-9\s\_\(\)\-\.] ]]; then
	  echo "\n=================================\n"
	  tmp=$(date +%N)
	  cp -v "$srcfile" $tmp
	  tmpfilenames+=("$tmp")
	fi
	
	## Go to https://trac.ffmpeg.org/wiki/Concatenate then section "Using intermediate files"
	## For "-c:v" option, go to https://ffmpeg.org/ffmpeg.html#Stream-selection
	ffmpeg -i $tmp -c:v copy -bsf:v h264_mp4toannexb "$tmp.ts"
	
	concat+="$tmp.ts|"
done

## Start merging videos here
outputname="mergedvideos-$(date +%s).mp4"
ffmpeg -i "concat:$concat" -c:v copy -bsf:a aac_adtstoasc "$outputname"


## ----------------------------------------------------------------

## Remove temporary files
echo "[DEB] Temp files: ${tmpfilenames[@]}"
for f in ${tmpfilenames[@]}; do 
	rm $f
done


## Remove intermeditate files
rm *.ts

