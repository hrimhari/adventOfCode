#!/bin/bash

MD5=$(which md5 md5sum | head -1)

magic=$1
if [ "$1" = "-t" ]; then
	test=1
	magic=ihgpwlah
fi

declare -a start=(1 1)
declare -a end=(7 7)

# Path stack
# Structure:
#   Key: step#
#   Value: list of coords in form of "PATH1,x1,y1 PATH2,x2,y2 ...", where PATH is composed of a sequence of either U, L, D or R.
declare -A pathStack=()

# Directions
declare -A directions=([U]=0 [D]=1 [L]=2 [R]=3)

# Path to doors
declare -A pathToDoors=()

# Latest paths leading to end
declare arrivedPaths=""

width=8
height=8

computeDoors() {
	local x=$1
	local y=$2
	local path=${3:1}

	pathToDoors[$3]="$(echo -e "${magic}${path}\c" | $MD5 | sed -e "s/[0-9]/0/g" -e "s/[a-f]/1/g" -e "s/./& /g" | cut -c1-8)"
}

hasArrived() {
	local x=$1
	local y=$2

	return $((x == ${end[0]} && y == ${end[1]} ? 0 : 1))
}

print() {
	echo

	local lx
	local ly
	local path=$1
	local x=$2
	local y=$3
	local -a doors=(${@:4})

	# Header
	for ((ly=-${#width}; ly < 0; ly++)) {
		printf "%3.3s" ""
		for ((lx=0; lx<width; lx++)) {
			printf "%1.1s" "${lx:$ly:1}"
		}
		echo
	}
	
	for ((ly=0; ly<=height; ly++)) {
		printf "%2.2s " "$ly"
		for ((lx=0; lx<=width; lx++)) {
			if [ $lx -eq 0 ] || [ $ly -eq 0 ] || [ $lx -eq $width ] || [ $ly -eq $height ] || [ $(((lx % 2) + (ly % 2))) -eq 0 ]; then
				# Wall
				printf "#"
			else
				case "$lx,$ly" in
					"$((x-1)),$y")
						# Left
						printf "%1.1s" "${doors[2]}";;
					"$x,$((y-1))")
						# Up
						printf "%1.1s" "${doors[0]}";;
					"$((x+1)),$y")
						# Right
						printf "%1.1s" "${doors[3]}";;
					"$x,$((y+1))")
						# Down
						printf "%1.1s" "${doors[1]}";;
					"${start[0]},${start[1]}")
						printf S;;
					"${end[0]},${end[1]}")
						printf E;;
					"$x,$y")
						printf P;;
					*)
						printf " ";;
				esac
			fi
		}
		echo
	}

	echo -e "\n${width}x${height} step=$step coord=${x},${y} end=${end[*]}"
}

directionToCoord() {
	local x=$1
	local y=$2
	local direction=$3

	case "$direction" in
		"D") let "y+=2";;
		"R") let "x+=2";;
		"U") let "y-=2";;
		"L") let "x-=2";;
	esac

	echo "$x $y"
}

isValidCoord() {
	local x=$1
	local y=$2

	return $((x >= 1 && y >= 1 && x < width && y < height? 0 : 1)) 
}

nextMove() {
	local path=$1
	local x=$2
	local y=$3
	local step=$4

	echo "Where to from $path,$x,$y step $step?"
	local direction
	local coord
	local found=0
	local attemptedList="${pathStack[$step]}"
	
	local -a doors=(${pathToDoors[$path]})

	local -A distances=()
	local distance
	local -A coords=()
	local directionIndex
	for direction in ${!directions[@]}; do
		directionIndex=${directions[$direction]}
		if [ ${doors[${directionIndex}]} -eq 0 ]; then
			# Door closed
			echo "Door closed: $direction" >&2
			continue
		fi
		coords[$direction]="$(directionToCoord $x $y $direction)"
	done
		
	#declare -p doors >&2
	#declare -p coords >&2
	local isValid
	for direction in ${!coords[@]}; do
		coord="${coords[$direction]}"
		isValidCoord $coord
		isValid=$?
		if [ $isValid -ne 0 ]; then
			echo "Not valid: ${path}${direction}: $coord" >&2
			continue
		fi

		attempted=$(echo " ${attemptedList}" | fgrep --color=always " ${path}${direction},")
		if [ ${#attempted} -ne 0 ]; then
			#echo "Attempted: ${path}${direction}: ${attempted}" >&2
			echo "Attempted: ${path}${direction}" >&2
			continue
		fi

		found=1
		break
	done

	if [ $found -eq 1 ]; then
		echo "Next direction chosen: ${path}${direction}: $coord" >&2
		nextCoord=$coord
		nextDirection=$direction
		return 0
	else
		echo "No coord chosen" >&2
		return 1
	fi
}

toStack() {
	local coord=$1
	local step=$2

	pathStack[$step]+=" $coord"
}

shortestPath() {
	local x
	local y
	local step=$1
	local coord
	local nextCoord
	local nextDirection
	local tempShortest=0
	local moved=0
	local path="$2"
	local arrived=""

	if [ ${#pathStack[$step]} -eq 0 ]; then
		echo "No more coords at step=$step"
		return 1
	fi

	let step++

	# Stack from current step
	for coord in ${pathStack[$((step-1))]}; do
		read path x y <<<"$(echo $coord | tr ',' ' ')"

		if hasArrived $x $y; then
			echo "Ended (arrived) path: $path"
			continue
		fi

		computeDoors "$x" "$y" "$path"

		print "$path" "$x" "$y" ${pathToDoors["$path"]}

		while nextMove "$path" "$x" "$y" $step; do
			if hasArrived $nextCoord; then
				echo "Arrived at $nextCoord in $step with path ${path:1}${nextDirection}" 
				#exit 0
				arrived="$step:${path:1}${nextDirection}"
			fi
			toStack $(echo ${path}$nextDirection $nextCoord | tr ' ' ',') $step
		done
	done

	unset pathStack[$((step-1))]

	if [ ${#arrived} -ne 0 ]; then
		echo "Possible paths: $arrived" >&2
		arrivedPaths=$arrived
	fi

	# Reenter on next step
	shortestPath $step $shortest
}

toStack S,${start[0]},${start[1]} 0

shortestPath 0 "S"
echo "Shortest: $?"
print
