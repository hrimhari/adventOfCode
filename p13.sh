#!/bin/bash

magic=$1
declare -a start=(1 1)

# Maze computed as needed
# Structure:
#   Key: 'x y'
#   Value: 0 for empty, 1 for wall
declare -A maze=()

declare -a binary=(0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111)

itob() {
	local int=$1
	local ix=$(printf "%x" $int)
	local i

	for ((i=0; i<${#ix}; i++)) {
		echo -e "${binary[${ix:i:1}]}\c"
	}
}

computeCoord() {
	local x=$1
	local y=$2

	local coord=$(( (x*x + 3*x + 2*x*y + y + y*y) + magic))
	coord=$(itob $coord | sed "s/./&+/g")

	let "coord = ($coord 0) % 2"
	
	maze["$x $y"]=$coord

	echo $coord
}

getCoord() {
	local x=$1
	local y=$2

	local coord=${maze["$x $y"]}

	if [ "$coord" = "" ]; then
		coord=$(computeCoord $x $y)
	fi

	echo $coord
}
