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
nospace_names=()
tmpfilenames=()

for srcfile in "${srcfiles[@]}"; do
	echo "[DEB] srcfile: $srcfile"
	
	tmp=$srcfile
	
	## ffmpeg does not work when source file's name 
	## conains whitespace or special characters (e.g. japanese alphabet)
	
	if [[ "$srcfile" =~ [^a-zA-Z0-9\ \_\(\)\-\.] ]]; then  
		## if contains spacial characters, make a copy of source file with simple name 
		## and let ffmpeg work on the copy instead
		tmp=$(date +%N)
		cp -v "$srcfile" $tmp
		tmpfilenames+=("$tmp") 
	elif [[ "$srcfile" =~ [\ ] ]]; then  
		## if contains whitespace, just rename the source file instead of making a copy
	  	## so this script won't eat too much disk space,
	  	## and it's easy to rename them back.
		tmp=$(echo "$srcfile" | tr " " "_") 
		mv "$srcfile" "$tmp"
		nospace_names+=("$tmp")
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

## Remove the copies of source files
echo "[DEB] Temp files: ${tmpfilenames[@]}"
for f in ${tmpfilenames[@]}; do 
	rm $f
done

## Renamed source files back
echo "[DEB] Renamed files: ${nospace_names[@]}"
for f in ${nospace_names[@]}; do 
	originalname=$(echo $f | tr "_" " ")
	mv "$f" "$originalname"
done

## Remove intermeditate files
rm *.ts

