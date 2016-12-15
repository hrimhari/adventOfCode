#!/bin/bash

declare -A discs=()
declare -A discPositions=()
numDiscs=0
# Read input
while read discdisc discNum has numPositions positions at time it is at positionposition position; do
	discs[$discNum]=$numPositions
	discPositions[$discNum]=$position
	let "numDiscs = numDiscs <= discNum ? discNum + 1: numDiscs"
done <<<"$(echo "$1" | tr -d '#;,.' | grep -v "^$")"

turnDisc() {
	local discNum=$1
	local steps=${2:-1}

	let "discPositions[$discNum]=(discPositions[$discNum] + steps) % discs[$discNum]"
}

turnDiscs() {
	local discNum

	for ((discNum = 1; discNum < numDiscs; discNum++)) {
		turnDisc $discNum
	}
}

timeIsRight() {
	local discNum=0
	local times=""
	local future

	for ((discNum = 1; discNum < numDiscs; discNum++)) {
		future=$(((discPositions["$discNum"] + discNum) % discs[$discNum]))
		if [ $future -ne 0 ]; then
			echo 0
			return
		fi
		times+=" time=$((time + discNum)),disc[$discNum]=${discPositions[$discNum]},future=$future"
	}
	echo "$times" >&2
	echo 1
}

print() {
	echo "time=$time, timeIsRight=$(timeIsRight)"
	declare -p discPositions
}

time=${2:-0}

# Forward discs in time
for ((discNum=1; discNum < numDiscs; discNum++)) {
	discPositions[$discNum]=$(((discPositions[$discNum] + time) % discs[$discNum]))
}

for ((; $(timeIsRight) != 1; ++time)) {
	turnDiscs
	print
}

print

