#!/bin/bash

HASHFILE=/tmp/p14.hashes
CANDIDATES=/tmp/p14.candidates


declare count=0
declare INPUT=$2

getKeys() {
	local hash=$1
	local temp=""

	hash=$(echo "$hash" | sed "s/^\([^-]*\)\([^-+]\)\2\2/\1-\2+-/")

	echo "$hash" | tr '-' '\n' | fgrep '+' | tr -d '+' | sed "s/./&&&&&/" | tr '\n' ' '
}

getFive() {
	local letter=$1
	local hash=$2

	echo "$hash" | sed -n "s/^.*${letter}\{5,5\}.*$/${letter}/p"
}

extractCandidates() {
	cat $INPUT | tr -d " -" | fgrep -n "" | tr ':' ' ' | while read i hash; do
		let i--
		((i % 50 == 0? 1 : 0)) && echo "$i:$hash" >&2
		keys=$(getKeys $hash | sed 's/ /\|/g' )

		if [ "$keys" != "" ]; then
			echo "$hash $i $((i+2)),+1000s/${keys}------/&/p" >> $CANDIDATES
		fi
	done
}

checkCandidates() {
	cat $CANDIDATES | while read hash i pattern; do
		if [ "$(sed -n "$(echo "$pattern" | sed 's/|/\\&/g')" < $INPUT)" != "" ]; then
			echo "Found $pattern, so $hash" >&2
			echo "${i} $hash" >> $HASHFILE
		fi
	done
}

if [ "$3" != "-c" ]; then
	> $CANDIDATES
	extractCandidates
fi

> $HASHFILE
checkCandidates

tail -1 $HASHFILE
