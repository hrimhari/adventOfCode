#!/bin/bash

if [ "$*" = "-t" ]; then
	test=1
fi

declare -a elements=("polonium" "thulium" "promethium" "ruthenium" "cobalt")
# Test
if [ "$test" = "1" ]; then
	elements=("polonium" "thulium")
fi

declare numColumns=$((${#elements[@]} * 2 + 1))
# Four rows over a sequential array
# Row structure:
# c0=E if elevator at this floor, c1=0G if generator for element 0, c2=0M if chip for element 0, etc., making for 11 columns  
# index formula:
#   (floor# - 1) * (numElements * 2 + 1), for elevator
#   (floor# - 1) * (numElements * 2 + 1) + 1 (skip elevator) + element# * 2 + (chip? 1 : 0), for items
declare -A floors=()

# Back references from movements to depth (number of steps) and previous movement
# Key: 'floors' expanded with declare -p without parenthesis
# Value: 'depth[space]key'
declare steps=$(tempfile -p p11steps)
declare stepCount=0

# Stack of moves to be tried
# Structure: "floor structure" stepCount fromFloor toFloor elem1 [elem2]
declare tryMoveStack=$(tempfile -p p11movestack)

# Initial structure
floors=([0]="E" [1]="0G" [3]="1G" [4]="1M" [5]="2G" [7]="3G" [8]="3M" [9]="4G" [10]="4M" [13]="0M" [17]="2M" )
# Test
if [ "$test" = "1" ]; then
	floors=([0]="E" [6]="0G" [2]="0M" [13]="1G" [4]="1M" )
fi

itemTypeNum() {
	case "$1" in
		"G") echo 0;;
		*) echo 1;;
	esac
}

getIndex() {
	local formula="(floorNum - 1) * numColumns + notElevator + itemNum * 2 + itemType"
	local floorNum=$1
	local notElevator=1
	local itemNum=0
	local itemType=0

	if [ "$2" = "E" ]; then
		notElevator=0
	else
		itemNum=${2:0:1}
		itemType=$(itemTypeNum ${2:1:1})
	fi

	echo $(($formula))
	if [ $? -ne 0 ]; then
		echo "floorNum=$floorNum numColumns=$numColumns notElevator=$notElevator itemNum=$itemNum itemType=$itemType" >&2
	fi
}

getFloorItems() {
	local floorNum=$1
	local i
	local itemIndex

	for ((i=1; i<numColumns; i++)) {
		itemIndex=$(( ($floorNum - 1) * numColumns + $i ))
		printf "${floors[$itemIndex]} "
	}
	echo
}

print() {
	local i
	local f
	local elem
	local itemTypeNum
	local item

	for ((f=4; f>0; f--)) {
		printf "$f "
		for ((i=0; i<numColumns; i++)) {
			item=${floors[$(( (f - 1) * numColumns + i ))]}

			printf "%2s " ${item:-..}
		}
		echo
	}

	for ((i=0; i<5; i++)) {
		printf "${i}=${elements[$i]} "
	}
	echo
}

getPossibleMoves() {
	local floorNum
	for ((floorNum=1; floorNum<5; floorNum++)) {
		if [ "${floors[$(( (floorNum - 1) * numColumns))]}" = "E" ]; then
			break
		fi
	}

	local possibleFloors=""
	local possibleFloor
	local nextStepCount=$((stepCount + 1))

	if [ $floorNum -gt 1 ]; then
		possibleFloors+="$((floorNum-1)) "
	fi
	if [ $floorNum -lt 4 ]; then
		possibleFloors+="$((floorNum+1))"
	fi

	local floorItems=$(getFloorItems $floorNum)
	for possibleFloor in $possibleFloors; do
		set -- $floorItems
		for a; do
			shift
			for b; do
				if tryMove $floorNum $possibleFloor $a $b; then
					printf "$nextStepCount $floorNum $possibleFloor $a $b\n"
				else
					printf "not possible: $nextStepCount $floorNum $possibleFloor $a $b\n" >&2
					:
				fi
			done
			if tryMove $floorNum $possibleFloor $a; then
				printf "$nextStepCount $floorNum $possibleFloor $a\n"
			else
				printf "not possible: $nextStepCount $floorNum $possibleFloor $a\n" >&2
				:
			fi
		done
	done
}

tryMove() {
	local fromFloor=$1
	local toFloor=$2
	shift 2
	local items=$*
	local floorItems

	take $fromFloor $items
	floorItems=$(getFloorItems $fromFloor)
	if ! checkUseless $fromFloor $toFloor $items && checkCombination $floorItems; then
		drop $fromFloor $items
		return 1
	fi

	drop $toFloor $items
	#declare -p floors
	checkHistory && checkCombination $(getFloorItems $toFloor)
	toCheck=$?
	take $toFloor $items
	drop $fromFloor $items

	return $toCheck
}

checkUseless() {
	local fromFloor=$1
	local toFloor=$2
	shift 2
	local itemCount=$#

	if [ $itemCount -eq 1 ]; then
		local direction=$((toFloor - fromFloor))
		local floor
		local i
		for ((floor=fromFloor; floor > 0 && floor < 5; floor += direction)) {
			for ((i = 1; i < numColumns; i++)) {
				if [ "${floors[$(( (floor - 1) * numColumns + i))]}" != "" ]; then
					return 0
				fi
			}
		}

		# Elevator is taking one item only but there's nothing else in the direction where it's going
		echo "Useless" >&2
		return 1
	fi

	return 0
}

checkHistory() {
	#local floorDump=$(dumpFloors)
	local floorDump=$(getFloorCount)

	#if fgrep -q "$floorDump" $steps $tryMoveStack; then
	if fgrep -q "$floorDump" $tryMoveStack; then
		echo "In history" >&2
		return 1
	fi

	return 0
}

take() {
	local floorNum=$1
	shift
	local items=$*
	local itemIndex
	for item in $items; do
		itemIndex=$(getIndex $floorNum $item)

		unset floors[$itemIndex]
	done
}

drop() {
	local floorNum=$1
	shift
	local items=$*
	local item
	local itemIndex
	
	for item in $items; do
		itemIndex=$(getIndex $floorNum $item)

		floors[$itemIndex]=$item
	done
}

checkCombination() {
	local -a generators
	local -a chips
	local item
	local items=$*

	generators=()
	chips=()

	for item in $items; do
		case "${item:1:1}" in
			"G")
				generators[${item:0:1}]=1;;
			*)
				chips[${item:0:1}]=1;;
		esac
	done

	for ((item=0; item<5; item++)) {
		if ([ "${chips[$item]}" = "1" ]) && ([ "${generators[$item]}" = "" ]) && ([ ${#generators[@]} -gt 0 ]); then
#			echo "*****"
#			echo "BOOM! ${item}G=${generators[$item]} ${item}M=${chips[$item]} #generators=${#generators[@]}"
#			echo "*****"
			return 1
		fi
	}
	return 0
}

isComplete() {
	local i
	local count=0
	local floorIndex
	#set -xv
	for ((i=1; i<numColumns; i++)) {
		floorIndex=$((3 * numColumns + $i))
		if [ "${floors[$floorIndex]}" != "" ]; then
			let count++
		fi
	}

	local result=$((count == (numColumns - 1)? 0 : 1))
	set +xv
	return $result
}

move() {
	local possibleMove=$(sed -n "$((count+1))p" < $tryMoveStack)
	#tryMoveStack=("${tryMoveStack[@]:1}")
	eval set -- $possibleMove
	local stackCount=$(wc -l < $tryMoveStack)
	echo "stackDepth=$((stackCount - count)) |$1| ${@:2}" >&2
	eval floors=($1)
	local nextStepCount=$2
	local fromFloor=$3
	local toFloor=$4
	shift 4
	local items
	items="${1} ${2}"

	local previousFloors=$(dumpFloors)
	local previousCount=$stepCount

	stepCount=$nextStepCount
	take $fromFloor $items
	drop $toFloor $items
	unset floors[$(( (fromFloor - 1) * numColumns))]
	floors[$(( (toFloor - 1) * numColumns))]="E"

	local floorDump=$(dumpFloors)
	local floorCount=$(getFloorCount)
	echo "[\"$floorDump\"]=\"$previousCount \'$floorCount\' $previousFloors\"" >> $steps

	if isComplete; then
		print
		echo "Done in $stepCount"
		exit
	fi

	stackPossibleMoves
}

stackPossibleMoves() {
	local possibleMoves=$(getPossibleMoves)
	local floorDump="$(dumpFloors)"
	local floorCount="$(getFloorCount)"
	local toStack
	echo -e "Stacking:\n$possibleMoves\n"

	while read possibleMove; do
		if [ "$possibleMove" = "" ]; then
			echo "WARNING: empty move!" >&2
			continue
		fi
		toStack="'$floorDump' $possibleMove '' $floorCount"
		echo "$toStack" >> $tryMoveStack
	done <<<"$possibleMoves"
}

dumpFloors() {
	local floorDump=$(declare -p floors | cut -d\( -f2 | cut -d\) -f1 | tr ' ' '\n' | sort -t= -k1,1 | tr '\n' ' ')
	#echo "$floorDump" >&2
	echo "$floorDump"
}

getFloorCount() {
	local floorNum
	local i
	local -A floorCount=()
	local gCount
	local mCount

	#set -xv
	for ((floorNum=1; floorNum<5; floorNum++)) {
		let gCount=0 mCount=0
		for ((i=1; i<numColumns; i++)) {
			if [ "${floors[$(( (floorNum - 1) * numColumns + i))]}" != "" ]; then
				case "$((i % 2))" in
					"1") let gCount++;;
					*) let mCount++;;
				esac
			fi
		}
		floorCount[$floorNum]="${gCount},${mCount}"
	}

	declare -p floorCount | cut -d\( -f2 | cut -d\) -f1 | tr ' ' '\n' | sort | tr '\n' ' '
	set +xv
}

> /tmp/p11.out
print
stackPossibleMoves
count=0
while [ $count -lt $(fgrep -c "" $tryMoveStack) ]; do
	move
	#if [ $((count % 50)) -eq 0 ]; then
		print
	#fi
	let count++
done

rm $tryMoveStack $steps
