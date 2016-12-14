#!/bin/bash

HASHFILE=/tmp/p14.hashes
CANDIDATES=/tmp/p14.candidates


declare count=0
declare INPUT=$2
declare -a pids=()

trap killAll 1 2 3 6 11

killAll() {
	for pid in ${pids[@]}; do
		kill -9 $pid
	done
	exit 1
}

spawn() {
	$* &
	pids+=($!)
}

getKeys() {
	local hash=$1
	local temp=""

	while [ "$temp" != "$hash" ]; do
		temp=$hash
		hash=$(echo "$hash" | sed "s/\([^-]*\)\([^-+]\)\2\2/\1-\2+-/")
	done

	echo "$hash" | tr '-' '\n' | fgrep '+' | head -1 | tr -d '+' | sed "s/./&&&&&/" | tr '\n' ' '
}

getFive() {
	local letter=$1
	local hash=$2

	echo "$hash" | sed -n "s/^.*${letter}\{5,5\}.*$/${letter}/p"
}

extractCandidates() {
	> $CANDIDATES
	tail -n +1 -f $INPUT | tr -d " -" | fgrep -n "" | tr ':' ' ' | while read i hash; do
		let i--
		((i % 50 == 0? 1 : 0)) && echo "$i:$hash" >&2
		keys=$(getKeys $hash | sed 's/ /\|/g' )

		if [ "$keys" != "" ]; then
			echo "$hash $i $((i+2)),+1000s/${keys}------/&/p" >> $CANDIDATES
		fi
	done
}

checkCandidates() {
	> $HASHFILE
	tail -n +1 -f $CANDIDATES | while read hash i pattern; do
		if [ "$(sed -n "$(echo "$pattern" | sed 's/|/\\&/g')" < $INPUT)" != "" ]; then
			echo "Found $pattern, so $hash" >&2
			echo "${i} $hash" >> $HASHFILE
		fi
	done
}

computeOneHash() {
	local in=$1
	echo -e "${in}\c" | md5sum | tr -d ' -'
}

computeHashes() {
	local salt=$1
	local core=$2
	local cores=$3
	local i=$core
	local stretch=0
	local in

	while true; do
		((i % 1 == 0? 1 : 0)) && echo "$i hash(es) ($core of $cores)..." >&2
		in=${salt}${i}
		for ((stretch=0; stretch <= 2016; stretch++)) { 
			in=$(computeOneHash $in)
		}
		echo $in >> $INPUT
		let i+=$cores
	done
}

> $INPUT
cores=10
for ((core=0; core<$cores; core++)) {
	spawn computeHashes $1 $core $cores
}

sleep 1
spawn extractCandidates
sleep 1
spawn checkCandidates

while [ $(wc -l < $HASHFILE) -lt 64 ]; do
	sleep 10
done

killAll
