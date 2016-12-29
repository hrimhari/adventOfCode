#!/bin/bash

trap "killprocs; exit 1" 1 2 3 6 9 11

set -b

killprocs() {
	while [ "$(jobs -r)" != "" ]; do
		echo "Kill %.."
		kill -9 %
	done
	rm -f $SEQFIFO
}

PROCS=${1:-1}

if [ "$2" != "" ]; then
	MAZE=$(cat /tmp/p24.test)
else
	MAZE=$(cat /tmp/p24.input)
fi

width=$(head -1 <<<"$MAZE" | tr -d '\n' | wc -c)
height=$(wc -l <<< "$MAZE")

MAZE=${MAZE//$'\n'}

getTarget() {
        local target=$1
	local pos=${MAZE%${target}*}
	pos=${#pos}

	echo "$((pos % width)) $((pos / width))"
        #echo "$(($(fgrep $target <<< "$MAZE" | tr -d '\n' | wc -c) - 1)) $(($(fgrep -n $target <<<"$MAZE" | cut -d: -f1) - 1))"
}

declare -A targets=()
declare visited=""

for target in $(sed -n -e "s/[^0-9]//g" -e "s/./& /g" -e '/^$/!p' <<<"$MAZE" | tr '\n' ' '); do 
        targets+=(["$(getTarget $target)"]=$target)
done

declare start="$(getTarget 0)"

# Path stack
#   Value: list of coords in form of "PATH1,x1,y1\nPATH2,x2,y2 ...", where PATH is composed of a sequence of either U, L, D or R.
STACK=/tmp/p24.stack
TMP=/tmp/p24.tmp
HIST=/tmp/p24.history
CURRENT=/tmp/p24.current
HVISITED=/tmp/p24.highest

SEQFIFO=/tmp/p24.seqfifo
LOG=/tmp/p24.log

# Latest paths leading to end
declare arrived=""

lastTarget=0

visitedTarget() {
	local x=$1
	local y=$2
        local target=${targets["$x $y"]}

        if [ "$target" != "" ]; then
                echo $target
        fi
}

seqGenerator() {
	local start=$1
	local multi=100000
	local end=$((start+multi))

	while true; do
		echo "Generating $start to $end..."
		seq $start $end >&10
		((start=end + 1, end = start + multi))
	done
}

hasArrived() {
	[ ${#visited} -eq ${#targets[@]} ]
}

print() {
	local lx
	local ly
	local path=$1
	local x=$2
	local y=$3

	echo -e "$proc: ${width}x${height} step=$step coord=${x},${y} end=${end[*]} counter=$counter left=$((stackCount=$(wc -l < $STACK) - counter)) tillNextStep=$((nextStepCounter - counter)) visited=$visited highestVisitedCount=$highestVisited}"
}

printPath() {
	local myMaze=$MAZE
	local tmpMaze=$MAZE
	local path=$1
	local x
	local y
	local pos
	local errors=""
	local item
	local marker

	read x y <<<"$start"
	
	for direction in $(sed "s/./& /g" <<<"$path");do
		case "$direction" in
			U) ((y--));;
			D) ((y++));;
			L) ((x--));;
			R) ((x++));;
		esac

		item=${myMaze:$((pos=y*width + x)):1}
		marker=a

		case "$item" in
			[a-z])
				marker=$(printf "\x$(printf "%x" $((1 + $(printf "%d" "'$item"))))")
				;&
			".") 
				tmpMaze=""
				if [ $pos -gt 0 ]; then
					tmpMaze=${myMaze:0:$pos}
				fi
				tmpMaze+="a${myMaze:$((pos+1))}"
				;;
			"#")
				errors+="$x,$y: wall!"$'\n'
				;;

	
		esac
		myMaze=$tmpMaze
	done

	for ((y = 0; y < height; y++)) {
		echo "${myMaze:$((y*width)):width}"
	}
	[ ${#errors} -gt 0 ] && echo "$errors"
}

#directionToCoord() {
#	local x=$1
#	local y=$2
#	local direction=$3
#
#	case "$direction" in
#		"D") let "y+=2";;
#		"R") let "x+=2";;
#		"U") let "y-=2";;
#		"L") let "x-=2";;
#	esac
#
#	echo "$x $y"
#}

isValidCoord() {
	local x=$1
	local y=$2

	((x >= 1 && y >= 1 && x < width && y < height)) 
}

isWallCoord() {
        local x=$1
        local y=$2
        #local element=$(sed -n "$((y+1))s/^.\{$x,$x\}\(.\).*$/\1/p" $MAZE)
        local element=${MAZE:$((y*width + x)):1}

        [ "$element" = "#" ]
}

isLoopCoord() {
        local fromX=$1
        local fromY=$2
        local direction=$3
        local path=$4
	#local testVisited=$(visitedTarget $fromX $fromY)

	#{
	# 	[ "$testVisited" != "" ] && fgrep -q "$testVisited" <<<"$visited"
	#} || grep -q ",$fromX,$fromY,${visited}$" $STACK
	grep -q "^$fromX,$fromY,${visited}$" $HIST
}

nextMove() {
	local path=$1
	local x=$2
	local y=$3
	local tempX=0
	local tempY=0
	local step=$4

	echo "$proc: Where to from $path,$x,$y,$visited step $step?" >> $LOG
	local direction
	local coord
	local found=0

	local distance
	local directionIndex
	local attempted
	local isValid
	local discarded=""

	nextDirections=""

	for direction in U L D R; do
		case "$direction" in
			U)
				((tempY=y-1,tempX=x));;
			R)
				((tempX=x+1,tempY=y));;
			D)
				((tempY=y+1,tempX=x));;
			L)
				((tempX=x-1,tempY=y));;
		esac
		coord="$tempX $tempY"

		! isValidCoord $coord && { discarded+=" $direction:invalid"; continue; }
		isWallCoord $coord && { discarded+=" $direction:wall"; continue; }
		isLoopCoord $coord $direction $path && { discarded+=" $direction:loop"; continue; }

		found=1
                toStack "${path}${direction},$tempX,$tempY,$visited" $step
		nextDirections+="$direction $coord"$'\n'
	done

	case "$found" in
		1)
			echo "$proc: Discarded: $discarded, Next directions chosen: "${nextDirections} >> $LOG
			return 0
			;;
	esac
	echo "$proc: No directions chosen. Discarded: $discarded" >> $LOG
	return 1
}

toStack() {
	local coord=$1

	let stackCount++
	flock $STACK -c "stdbuf -o0 echo \"$coord\" >> ${STACK}"
	flock $HIST -c "stdbuf -o0 echo \"${coord#*,}\" >> ${HIST}"
}

shortestPath() {
	local proc=$1
	local x
	local y
	local step
	local coord
	local nextCoord
	local nextDirection
	local nextDirections
	local tempShortest=0
	local moved=0
	local path
	local counterSeek=0
	local nextStepCounter=0
	local stackCount
	local previousStep=0
	local previousCounter
	local doors=""
	local tmpVisited=""
	local noCoordTries=0

	nextStepCounter=$(egrep -n "^[SLRDU]{$((step+1)),$((step+1))}," $STACK | head -1 | cut -d: -f1)

	exec {stacklock}<$STACK {counterlock}<$CURRENT {hvLock}<$HVISITED
	

	echo "$proc: lock descriptors: stack=$stacklock counter=$counterlock, highestVisited=$hvLock"

	oldIFS="$IFS"
	IFS=",$IFS"
	while true; do
		while true; do
			flock $stacklock
			read -u 5 path x y visited
			flock -u $stacklock
			[ ${#path} -gt 0 ] && break
			[ $((noCoordTries++)) -gt 5 ] && break 2
			sleep 1
		done
		flock $counterlock
		read -u 10 counter
		echo "${counter}P$(fgrep pos /proc/self/fdinfo/5 | cut -d\	 -f2)" > $CURRENT
		flock -u $counterlock
		step=${#path}

		case "$step" in
			$previousStep)
				;;
			*)
				stackCount=$(wc -l < $STACK)
				previousStep=$step
				nextStepCounter=$(egrep -n "^[SLRDU]{$((step+1)),$((step+1))}," $STACK | head -1 | cut -d: -f1)
				nextStepCounter=${nextStepCounter:-$stackCount}
				;;
		esac

		tmpVisited=$(visitedTarget $x $y)
		[ ${#tmpVisited} -gt 0 ] && [ "${visited%${tmpVisited}*}" = "$visited" ] && visited+=$tmpVisited

		flock $hvLock
		read highestVisited < $HVISITED
		highestVisited=${highestVisited:-0}

		#[ ${#visited} -lt ${highestVisited} ] && {
		#	flock -u $hvLock
		#	echo "$proc: visited(${#visited}) < highestVisited($highestVisited), skip..."
		#	continue
		#}
		[ ${#visited} -lt $((highestVisited - 1)) ] && {
			flock -u $hvLock
			echo "$proc: visited(${#visited}) < highestVisited($highestVisited), skip..."
			continue
		}
		
		[ ${#visited} -gt $highestVisited ] && {
			echo $((highestVisited = ${#visited})) > $HVISITED
		}
		flock -u $hvLock

		((counter % 10 == 0)) && print "$path" $x $y "${doors}"

		hasArrived $x $y && {
			echo "$proc: Ended (arrived) path ($((${#path}-1))): ${path:1}"
			printPath $path
			arrived="$step:$path"
			exit 0
		}

		nextMove "$path" "$x" "$y" $step
	done

	echo "$proc: No more coords at step=$step"
	exit 1
}

spawn() {
	trap - 1 2 3 6 9 11
	$*
}

touch $STACK $CURRENT $HVISITED
if [ $(wc -l < $STACK) -eq 0 ]; then
	toStack "S,${start[0]},${start[1]}," 0
fi

declare highestVisited=$(cat $HVISITED)
highestVisited=${highestVisited:-0}

declare counter=$(cat $CURRENT | cut -dP -f1)
counter=${counter:-0}
declare position=$(cat $CURRENT | cut -s -dP -f2)

exec 5<>$STACK

if [ "$position" != "" ]; then
	echo -e "Calculating counter...\c"
	echo " $counter"
	echo "Seeking to position $position..."
	dd of=/dev/null bs=$position count=1 <&5
else
	while [ $((counterSeek++)) -lt $counter ]; do
		((counterSeek % 100 == 1 ? 1 : 0)) && echo -e "\rSeeking to $counter... ($counterSeek)\c"
		read -u 5 path
	done
fi

rm -f $SEQFIFO
mkfifo $SEQFIFO

exec 10<>$SEQFIFO

spawn seqGenerator $counter & 

for proc in $(seq 1 $PROCS); do
	spawn shortestPath $((proc - 1)) &
	sleep 2
done

while [ $(jobs | wc -l) -gt 1 ]; do
	wait -n
done

killprocs

