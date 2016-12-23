#!/bin/bash

NODES=/tmp/p22.0.cleaned
TIME=0

declare start=""
declare end="0 0"
declare width=0
declare height=0
declare dataLocation=""
declare historyStateCache=""

counter=${1:-0}

# Key: "x y", Value: int
declare -A nodeAvailInfo=()
declare -A nodeUsedInfo=()

# Path stack
# Structure: list of nodes becoming empty on each step and a pointer to the node states. Example:
#   stateHistoryLine:x1,y1:x2,y2:x3,y3...
STACK=/tmp/p22.stack
CURRENT=/tmp/p22.stack.current
NEXT=/tmp/p22.stack.next

# History
# Structure: output of declare -p nodeUsedInfo;output of declare -p nodeAvailInfo
HISTORY=/tmp/p22.history

# Used history: to check if a state was already recorded
# Structure: x1,y1:usedAmount x2,y2:usedAmount ...
USEDHISTORY=/tmp/p22.usedhistory

readNodes() {
	local usedSize
	local availSize
	local nodeName
	local x
	local y
	while read nodeName t2 usedSize availSize t3; do
		read x y <<<"$(echo $nodeName | tr '-' ' ' | cut -d\  -f2,3 | tr -d 'xy')"
		echo -e "Read $x,$y '$usedSize' '$availSize'      \r\c"
		nodeAvailInfo["$x $y"]=$availSize
		nodeUsedInfo["$x $y"]=$usedSize

		if [ $height -le $y ]; then
			let "height=y + 1"
		fi

		if [ $width -le $x ]; then
			let "width=x + 1"
		fi

		if [ $usedSize -eq 0 ]; then
			start="$x $y"
		fi
	done < $NODES
	echo
}

hasArrived() {
	if [ "$dataLocation" = "$end" ]; then
		return 0
	fi
	return 1
}

isValidCoord() {
	local x=$1
	local y=$2

	return $((x >= 0 && y >= 0 && x < width && y < height? 0 : 1)) 
}

isValidMove() {
	local fromX=$1
	local fromY=$2
	local toX=$3
	local toY=$4

	if ! isValidCoord $fromX $fromY; then
		echo "Invalid origin $fromX $fromY"
		return 1
	fi

	if ! isValidCoord $toX $toY; then
		echo "Invalid destination $toX $toY"
		return 1
	fi

	if [ ${nodeUsedInfo["$toX $toY"]} -ne 0 ]; then
		echo "$toX,$toY not empty"
		return 1
	fi

	if echo "$path" | grep -q ":$toX,$toY:$fromX,$fromY$"; then
		echo "Just came from $toX,$toY"
		return 1
	fi

	local distance=$(((fromX - toX)**2 + (fromY - toY)**2))
	if [ $distance -ne 1 ]; then
		echo "Not adjacent ($fromX $fromY) <-> ($toX $toY) distance=$distance"
		return 1
	fi

	if [ ${nodeAvailInfo["$toX $toY"]} -lt ${nodeUsedInfo["$fromX $fromY"]} ]; then
		echo "Insuficient space ${nodeAvailInfo[$toX $toY]}($toX $toY) to store ${nodeUsedInfo[$fromX $fromY]}($fromX $fromY)"
		return 1
	fi
}

loadStates() {
	local index=$1
	local cmd=""

	if [ $index -gt $historyCounter ]; then
		while [ $historyCounter -lt $index ] && read -u 6 cmd; do
			let historyCounter++
			echo -e "\rSkipping history to $index($historyCounter)...\c"
		done

		if [ "$cmd" = "" ]; then
			echo "ERROR! Unable to read history $index"
			exit 1
		fi

		historyStateCache="$(echo "$cmd" | sed "s/declare -A/declare -Ag/g")"
	elif [ $index -lt $historyCounter ]; then
		echo "ERROR! Cannot load $index < $historyCounter"
		exit 1
	else
		echo "Already have state $index in cache"
	fi

	unset nodeAvailInfo
	unset nodeUsedInfo
	eval $historyStateCache
	echo "Loaded history $index"
}

# Move data
doMove() {
	local fromCoord="$1"
	local toCoord="$2"
	echo "Move from: ($fromCoord)=${nodeUsedInfo[$fromCoord]}/${nodeAvailInfo[$fromCoord]}, ($x $y)=${nodeUsedInfo[$toCoord]}/${nodeAvailInfo[$toCoord]}"
	let "nodeAvailInfo[$fromCoord]+=nodeUsedInfo[$fromCoord], nodeAvailInfo[$toCoord]-=nodeUsedInfo[$fromCoord], nodeUsedInfo[$toCoord]=nodeUsedInfo[$fromCoord], nodeUsedInfo[$fromCoord]=0"
	echo "To: ($fromCoord)=${nodeUsedInfo[$fromCoord]}/${nodeAvailInfo[$fromCoord]}, ($toCoord)=${nodeUsedInfo[$toCoord]}/${nodeAvailInfo[$toCoord]}"
}

nextMove() {
	local step=$1
	local path=$2
	local x=$3
	local y=$4

	echo "Where to from '$path($x,$y)' step $step?"
	local direction
	local coord
	local found=0
	
	local distance
	local coords=""
	local directionIndex
	local moveDetails
	local fromTime
	local toTime

	for coord in "$((x-1)) $y" "$((x+1)) $y" "$x $((y - 1))" "$x $((y + 1))"; do
		fromTime=$(date +%s%N)
		if ! isValidMove $coord $x $y; then
			toTime=$(date +%s%N)
			[ $TIME -ne 0 ] && echo "isValidMove: $(((toTime - fromTime) / 1000000))"
			continue
		fi
		toTime=$(date +%s%N)
		[ $TIME -ne 0 ] && echo "isValidMove: $(((toTime - fromTime) / 1000000))"

		found=1
		fromTime=$(date +%s%N)
		toStack "$path" "$coord"
		toTime=$(date +%s%N)
		[ $TIME -ne 0 ] && echo "toStack: $(((toTime - fromTime) / 1000000))"
		coords+="($coord)"$'\n'
	done

	if [ $found -eq 1 ]; then
		echo "Next coords chosen: $coords" >&2
		return 0
	else
		echo "No coord chosen" >&2
		return 1
	fi
}

toStack() {
	local path="$1"
	local coord="$2"
	local historyLine="$((historyLines++))"

	echo "${historyLine}:${path}:$(echo $coord | tr ' ' ',')" >> $STACK
	echo "${historyLine}:${path}:$(echo $coord | tr ' ' ',')" >> $NEXT
}

gotStates() {
	local coord=$1
	echo "$path" | fgrep -q ":$coord:" && fgrep -q "$(declare -p nodeUsedInfo | tr -d '"' | cut -d\( -f2- | cut -d\) -f1 | sed "s/\[\([0-9]*\) \([0-9]*\)\]=\([0-9]*\) /\1,\2:\3 /g")" $USEDHISTORY
	return $?
}

logStates() {
	(declare -p nodeUsedInfo; declare -p nodeAvailInfo) | tr '\n' ';' >> $HISTORY
	declare -p nodeUsedInfo | tr -d '"' | cut -d\( -f2- | cut -d\) -f1 | sed "s/\[\([0-9]*\) \([0-9]*\)\]=\([0-9]*\) /\1,\2:\3 /g" >> $USEDHISTORY
	echo >> $HISTORY
}

swapStacks() {
	mv $NEXT $CURRENT
	> $NEXT
	exec 5<&-
	exec 5<$CURRENT
	counter=1
}

if [ $counter -eq 0 ]; then
	> $HISTORY
	> $USEDHISTORY
	> $STACK
fi

if [ ! -f $CURRENT ]; then
	cp $STACK $CURRENT
	cp $STACK $NEXT
fi

touch $HISTORY
declare historyLines=$(wc -l < $HISTORY)

exec 5<$STACK 6<$HISTORY
tempCounter=1

while [ $((tempCounter++)) -lt $counter ]; do
	echo -e "\rSkipping to $counter($tempCounter)...\c"
	read -u 5 path
done
echo

shortestPath() {
	local x
	local y
	local fromX
	local fromY
	local step
	local previousStep=0
	local coord
	local nextCoord
	local nextDirection
	local tempShortest=0
	local historyLine=0
	local historyCounter=0
	local moved=0
	local path=""
	local arrived=""
	local fromTime
	local toTime

	while ! hasArrived && read -u 5 path; do
		fromTime=$(date +%s%N)
		let counter++
		step=$(($(echo "$path" | sed "s/[^:]//g" | tr -d '\n' | wc -c) - 1))

		if [ $previousStep -eq 0 ]; then
			previousStep=$step
		elif [ $step -gt $previousStep ]; then
			previousStep=$step
			#swapStacks
		fi

		set -- $(echo $path | sed -e "s/^:/'' /" -e "s/^\([^:]*\):/\1 /" -e "s/[ :]\([^,:]*\),\([^:,]*\):\([^,:]*\),\([^:,]*\)$/& \1 \2 \3 \4/" -e "s/[ :]\([^,:]*\),\([^:,]*\)$/& '' '' \1 \2/")

		historyLine=$1
		path=$2
		x=$3
		y=$4
		fromX=$5
		fromY=$6

		toTime=$(date +%s%N)
		[ $TIME -ne 0 ] && echo "Preamble: $(( (toTime - fromTime) / 1000000))"

		if [ "$historyLine" != "0" ]; then
			fromTime=$(date +%s%N)
			loadStates $historyLine
			toTime=$(date +%s%N)
			[ $TIME -ne 0 ] && echo "loadStats: $(( (toTime - fromTime) / 1000000))"
		fi

		if [ "$x" != "''" ]; then
			fromTime=$(date +%s%N)
			doMove "$fromX $fromY" "$x $y"
			toTime=$(date +%s%N)
			[ $TIME -ne 0 ] && echo "doMove: $(( (toTime - fromTime) / 1000000))"
			moved=1
		else
			echo "Can't move just yet"
			logStates
		fi

		echo "counter='$counter' step='$step' history='$historyLine' path='$path' fromXY='$fromX','$fromY' xy='$x','$y'"
		coord="$fromX $fromY"

		if [ $moved -eq 1 ] && gotStates "$fromX,$fromY"; then
			echo "Been there, done that, got the states to prove."
			continue
		fi

		if hasArrived $coord; then
			echo "Arrived at $coord in $step with path ${path}:${coord}" 
			exit 0
		fi

		fromTime=$(date +%s%N)
		logStates
		toTime=$(date +%s%N)
		[ $TIME -ne 0 ] && echo "logStates: $(( (toTime - fromTime) / 1000000))"

		fromTime=$(date +%s%N)
		nextMove $step "$path" $coord
		toTime=$(date +%s%N)
		[ $TIME -ne 0 ] && echo "nextMove: $(( (toTime - fromTime) / 1000000))"
	done
}

readNodes

echo "Start=($start), end=($end), dim=(${width}x${height})"
if [ $counter -eq 0 ]; then
	toStack "" "$start"
fi

shortestPath

echo No moves left
