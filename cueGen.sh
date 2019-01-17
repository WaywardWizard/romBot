#!/bin/bash

unset clobber
TRACKMODE="MODE2/2352"

# Green info item
_g() { echo -e "\e[42m$1\e[0m"; }

_o() { echo -e "\e[43m$1\e[0m"; }

# Information item
_i() { echo -e "\e[47m$1\e[0m"; }

# Red info item
_r() { echo -e "\e[41m$1\e[0m"; }

printUsage() {
	if [ -z "$1" ]
	then
		cat <<- "EOF"
			Run with ./$0 <directoryWithBinFiles> [-c] 

			Generates cue files for binaries in the given directory. Supports case Where a disc image is spread
			over multiple binary files. Supports also folders with many games.

			An assumption is made that where an image is spread over multiple binaries, they will have a common 
			name excepting the regular pattern '(T|t)rack \d+'

			If the -c flag is given, any preexisting cue files will be clobbered

			EOF

		exit 1;
	fi
}

parseOptions() {
 	while getopts ":c" option
	do
		case $option in
			c)
				_o "Set clobber on"
				clobber="true";;
		esac
	done
}

# Identify all bin items belonging to the game to which the first list item belongs.
# 
# First argument is a newline separated list of binary file paths. (A single string/word
# with newlines separating the entries.) This list may contain many binaries from many games.
# 
# Once this function has been run $leftover shall contain all remining bins and $binlist shall
# contain the ordered list of bin files that belong to one game.
processBinlist() {

	# These are global to allow access in other functions (alternative is passing around
	# lists of things)
	unset binList
	unset leftover
	declare -ga binList
	declare -ga leftover

	IFS=$'\n'; for item in $1
	do

		# Escape literal chars in filename for later use as expression
		fileName="$(basename "$item")"
		escapedFileName="$( sed -E 's/\^|\.|\[|\{|\*|\?|\+|\\|\(|\)/\\&/g' <<< "$fileName")"
		trackNbr="$(grep -Po '(T|t)rack \d+' - <<< "$fileName" | grep -Po '\d+' )"

		# This is a multitrack item
		if [ ! -z "$trackNbr" ]
		then

			trackNbr="${trackNbr##0}"
			if [ -z "$trackNbr" ];then trackNbr="0";fi

			# Set pattern to first item in given binlist
			if [ -z $pattern ]
			then
				pattern="$(sed -E 's/(T|t)rack [[:digit:]]+/\1rack [[:digit:]]+/' <<< "$escapedFileName")"
			fi

			if [[ "$fileName" =~ $pattern ]]
			then
				binList["${trackNbr##0}"]="$item"
			else
				leftover="$item"
			fi
		else
			binList["1"]="$item"
		fi
	done
	IFS=''

	unset "pattern"

}

# Write a cue file for the set of bin files in $binList in the cwd
processGame() {

	nTrack="${#binList[@]}"

	if [ "$nTrack" == "0" ]
	then
		_r "No list of binaries belonging to a game are present. Provide a list of bin 
		files to process and pass them to processBinList()"
		exit 1;
	fi

	# Assume bin files for multiple games are contained in one directory and therefore
	# yield the game title from a binfile belonging to the game (not the containing directory)
	title="$( sed -E 's/[[:space:]]*(\(|\[|\{)?(T|t)rack [[:digit:]]+(\)|\]|\})?[[:space:]]*//' <<< "$( sed -E 's/\.bin$//' <<< "$(basename "${binList[-1]}")")")"

	_i "Processing game \e[1m'$title'\e[22m with $nTrack tracks"

	# Tracks start at 1 if not zero
	ixTrack="0"
	if [ ! -v binList[$ixTrack] ];then ixTrack="1";fi

	cueDirectory="$(dirname ${binList[$ixTrack]})"
	cueFile="$cueDirectory/${title}.cue"

	# Only modify cue file if clobber is specified or there is no pre-existing cue file.
	if [ "$clobber" == "true" ] || [ ! -e "$cueFile" ]
	then

		_g "Creating cue file '$(basename $cueFile)' for game '$title'"
		rm "$cueFile" 2> /dev/null
		touch "$cueFile"

		trackMode="$TRACKMODE"
		while [ -v binList[$ixTrack] ]
		do
			binFile="$(basename "${binList[$ixTrack]}")"

			tee -a "$cueFile" <<< "FILE \"$binFile\" BINARY" &>/dev/null
			tee -a "$cueFile" <<< "    TRACK $ixTrack $trackMode" &>/dev/null
			tee -a "$cueFile" <<< "        INDEX 00 00:00:00" &>/dev/null

			# Subsequent tracks have an audio trackmode. First has a $TRACKMODE mode"
			trackMode="AUDIO"
			((ixTrack++))
		done
	else
		_o "Cue file for $title already exists. Skipping"
	fi


}



# Process all bin files in a given directory (by grouping them as games and writing their cue files)
processDir() {

	binFiles="$(find "$1" -maxdepth 1 -iname *.bin -type f)"
	nBinFiles=$(($(wc -l <<< \"$binFiles\")))

	# Find will print a newline when it has no matches, this handles erroneous wc result inthis case
	if [ -z "$binFiles" ];then nBinFiles="0";fi

	if [ "$nBinFiles" != "0" ]
	then 
		_i "Processing $nBinFiles binary files in $1"

		# Process single game from directory
		processBinlist "$binFiles"
		processGame

		# Process any further games from directory
		if [ ${#leftover[@]} != "0" ];then _i "Processing leftover games in directory $1";fi

		while [ ${#leftover[@]} != "0" ]
		do
			processBinlist "${leftover[@]}"
			processGame
		done
	fi
}

printUsage "$@"
parseOptions "$2"
find "$1" -type d | while read dir
do
	processDir "$dir"
done


