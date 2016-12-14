#!/bin/bash

magic=$1
if [ "$1" = "-t" ]; then
	test=1
	magic=10
fi

declare -a start=(1 1)
declare -a end=(31 39)

if [ "$test" = "1" ]; then
	end=(7 4)
fi

# Maze computed as needed
# Structure:
#   Key: 'x y'
#   Value: 0 for empty, 1 for wall
declare -A maze=()
declare width=0
declare height=0

# Attempted steps
# Structure:
#   Key: step#
#   Value: list of attempted next steps in the form of "[x1 y1][x2 y2]..."
declare -A attemptedSteps=()

declare -A binary=([0]=0000 [1]=0001 [2]=0010 [3]=0011 [4]=0100 [5]=0101 [6]=0110 [7]=0111 [8]=1000 [9]=1001 [a]=1010 [b]=1011 [c]=1100 [d]=1101 [e]=1110 [f]=1111)

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

	let "width = $width > $x ? $width : ($x + 1), height = $height > $y ? $height : ($y + 1)"
}

ensureCoord() {
	local x=$1
	local y=$2

	local coord=${maze["$x $y"]}

	if [ "$coord" = "" ]; then
		computeCoord $x $y
		coord=${maze["$x $y"]}
	fi

	#echo $coord
}

hasArrived() {
	x=$1
	y=$2

	return $((x == ${end[0]} && y == ${end[1]} ? 0 : 1))
}

print() {
	echo

	local lx
	local ly
	local path=$*

	# Header
	for ((ly=-${#width}; ly < 0; ly++)) {
		printf "%3.3s" ""
		for ((lx=0; lx<width; lx++)) {
			printf "%1.1s" "${lx:$ly:1}"
		}
		echo
	}
	
	#local -A attemptedCoords=($(echo "${attemptedSteps[*]}" | sed "s/]/&=1/g"))
	for ((ly=0; ly<height; ly++)) {
		printf "%2.2s " "$ly"
		for ((lx=0; lx<width; lx++)) {
			case "$lx,$ly" in
				"${start[0]},${start[1]}")
					printf "S";;
				"${end[0]},${end[1]}")
					printf "E";;
				"$(echo $path | tr ' ' '|')---")
					printf "O";;
				*)
					case "${maze["$lx $ly"]}" in
						"1")	printf "#";;
						"0")	printf ".";;
						*)	printf "?";;
					esac;;
			esac
		}
		echo
	}

	echo -e "\n${width}x${height} step=$step coord=${x},${y} end=${end[*]}"
}

directionToCoord() {
	local x=$1
	local y=$2
	local direction=$3

	# 0: N
	# 1: E
	# 2: S
	# 3: W
	case "$direction" in
		"0") let "y++";;
		"1") let "x++";;
		"2") let "y--";;
		"3") let "x--";;
	esac

	echo "$x $y"
}

isValidCoord() {
	local x=$1
	local y=$2

	return $((x >= 0 && y >= 0? 0 : 1)) 
}

getDistance() {
	local x=$1
	local y=$2
	echo $(( (${end[0]} - x)**2 + (${end[1]} - y)** 2 ))
}

nextMove() {
	local x=$1
	local y=$2
	local step=$3

	echo "Where to from $x,$y step $step?"
	local direction
	local coord
	local found=0
	local attemptedList="${attemptedSteps[*]}"
	
	local -A distances=()
	local distance
	local -A coords=()
	for ((direction=0; direction < 4; direction++)) {
		coords[$direction]="$(directionToCoord $x $y $direction)"
		distances[$direction]=$(getDistance ${coords[$direction]})
	}
		
	declare -p distances | tr -d '][()"'"'" | cut -d= -f2- | tr ' ' '\n' | sort -n -t= -k2,2 >&2
	declare -p coords >&2
	local directions="$(declare -p distances | tr -d '][()"'"'" | cut -d= -f2- | tr ' ' '\n' | sort -n -t= -k2,2 | cut -d= -f1 | tr '\n' ' ')"
	echo "directions: $directions" >&2
	local isValid
	local mazeValue
	local attempted
	for direction in $directions; do
		coord="${coords[$direction]}"
		distance=${distances[$direction]}
		isValidCoord $coord && ensureCoord $coord
		isValid=$?
		mazeValue="${maze["$coord"]}"
		attempted="$(echo "$attemptedList" | fgrep --color=always "[$coord]")"
		if [ $isValid -ne 0 ]; then
			echo "Not valid: $coord" >&2
			continue
		fi

		if [ $mazeValue -ne 0 ]; then
			echo "Not walkable: $coord" >&2
			continue
		fi

		if [ ${#attempted} -ne 0 ]; then
			echo "Attempted: $coord" >&2
			continue
		fi

		found=1
		break
	done

	if [ $found -eq 1 ]; then
		echo "Next coord chosen: $coord" >&2
		nextCoord=$coord
		return 0
	else
		echo "No coord chosen" >&2
		return 1
	fi
}

shortestPath() {
	local x=$1
	local y=$2
	local step=$3
	local nextCoord
	local shortest=${4:-0}
	local tempShortest=0
	local moved=0
	local path="${@:5}"

	attemptedSteps[$step]+="[$x $y]"

	print $path

	if let "shortest != 0 && step > shortest ? 1 : 0"; then
		echo "Longer, aborting..."
		return 0
	fi 

	if ! hasArrived $x $y; then
		while nextMove $x $y $step; do
			moved=1
			echo "Moved" >&2
			#attemptedSteps[$step]+="[$nextCoord]"
			shortestPath $nextCoord $((step+1)) $shortest $path $x,$y
			tempShortest=$?
			if [ $tempShortest -ne 0 ]; then
				let "shortest = shortest == 0 || shortest > tempShortest ? tempShortest : shortest"
			fi
		done

		# End of path
		if [ $moved -eq 1 ]; then
			return $shortest
		else
			return 0
		fi
	else
		echo "Arrived: $step"
		return $step
	fi
}

shortestPath ${start[@]} 0
echo "Shortest: $?"
print
