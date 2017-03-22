#!/bin/bash

trap "killprocs; exit 1" 1 2 3 6 9 11

#
# REQUIRES 'md5' BUILTIN to be on the same directory as this script.
# See https://github.com/geirha/bash-builtins/blob/master/md5.c
enable -f $(cd $(dirname "$0") && pwd)/md5 md5

killprocs() {
	while [ "$(jobs)" != "" ]; do
		echo "Kill %.."
		kill -9 %
	done
	rm -f $SEQFIFO
}

PROCS=${2:-1}
#MD5=$(which md5 md5sum | head -1)

magic=$1
if [ "$1" = "-t" ]; then
	test=1
	magic=ihgpwlah
fi

declare -a start=(1 1)
declare -a end=(7 7)

# Path stack
#   Value: list of coords in form of "PATH1,x1,y1\nPATH2,x2,y2 ...", where PATH is composed of a sequence of either U, L, D or R.
STACK=/tmp/p17-b.${magic}.stack
TMP=/tmp/p17-b.${magic}.tmp
HIST=/tmp/p17-b.${magic}.history
SEQFIFO=/tmp/p17-b.${magic}.seqfifo
LOG=/tmp/p17-b.${magic}.log

CURRENT=/tmp/p17-b.${magic}.current

# Directions
declare -A directions=([U]=0 [D]=1 [L]=2 [R]=3)
declare -A directionToCoord=([U]="tempY=y-2,tempX=x" [D]="tempY=y+2,tempX=x" [L]="tempX=x-2,tempY=y" [R]="tempX=x+2,tempY=y")

# Latest paths leading to end
declare arrived=""

width=8
height=8

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

computeDoors() {
	local x=$1
	local y=$2
	local path=${3:1}

	#doors="$(echo -e "${magic}${path}\c" | $MD5 | sed -e "s/[0-9]/0/g" -e "s/[a-f]/1/g" -e "s/./& /g" | cut -c1-8)"
	md5 "${magic}${path}"
	#doors=$(sed -e "s/[0-9]a/0/g" -e "s/[b-f]/1/g" -e "s/./& /g" -e "s/^\(.\{8,8\}\).*$/\1/" <<<"$REPLY")
	doors=${REPLY//[0-9]/0 }
	doors=${doors//[a-f]/1 }
	doors=${doors:0:8}
}

hasArrived() {
	local x=$1
	local y=$2

	return $((x == ${end[0]} && y == ${end[1]} ? 0 : 1))
}

print() {
	local lx
	local ly
	local path=$1
	local x=$2
	local y=$3

	if false; then # No need for visual for now
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
	fi

	echo "$proc: ${width}x${height} step=$step coord=${x},${y} end=${end[*]} counter=$counter left=$((stackCount - counter)) tillNextStep=$((nextStepCounter - counter)) doors=${doors}"
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

	return $((x >= 1 && y >= 1 && x < width && y < height? 0 : 1)) 
}

nextMove() {
	local path=$1
	local x=$2
	local y=$3
	local tempX=0
	local tempY=0
	local step=$4

	echo "$proc: Where to from $path,$x,$y step $step?" >> $LOG
	local direction
	local coord
	local found=0

	local distance
	local directionIndex
	local attempted
	local isValid
	local discarded=""

	nextDirections=""

	for direction in ${!directions[@]}; do
		directionIndex=${directions[$direction]}
#		if [ ${doors:$((directionIndex*2)):1} -eq 0 ]; then
#			# Door closed
#			#echo "Door closed: $direction" >&2
#			discarded+=" $direction:door" 
#			continue
#		fi
		((${doors:$((directionIndex*2)):1} == 0)) && { discarded+=" $direction:door"; continue; }

		#coord="$(directionToCoord $x $y $direction)"
		((${directionToCoord[$direction]}))
		coord="$tempX $tempY"

#		if ! isValidCoord $coord; then
#			#echo "Not valid: ${path}${direction}: $coord" >&2
#			discarded+=" $direction:invalid" 
#			continue
#		fi

		! isValidCoord $coord && { discarded+=" $direction:invalid"; continue; }

		# Shouldn't happen, expensive
#		attempted=$(grep --color=always "^${path}${direction}," $STACK)
#		if [ ${#attempted} -ne 0 ]; then
#			#echo "Attempted: ${path}${direction}: ${attempted}" >&2
#			echo "Attempted: ${path}${direction}" >&2
#			discarded+=" $direction:already" 
#			continue
#		fi

		found=1
		# Done in main loop
#                if hasArrived $nextCoord; then
#                        echo "$proc: Arrived at $nextCoord in $step with path ${path:1}${nextDirection}"
#                        #exit 0
#                        arrived="$step:${path:1}${nextDirection}"
#                fi
                toStack "$(echo ${path}$direction $coord | tr ' ' ',')" $step
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
	local step=$2

	let stackCount++
	flock $STACK -c "stdbuf -o0 echo \"$coord\" >> ${STACK}"
}

longestPath() {
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

	nextStepCounter=$(egrep -n "^[SLRDU]{$((step+1)),$((step+1))}," $STACK | head -1 | cut -d: -f1)

	exec {stacklock}<$STACK
	exec {counterlock}<$CURRENT

	echo "$proc: lock descriptors: stack=$stacklock counter=$counterlock"

	oldIFS="$IFS"
	IFS=",$IFS"
	while { flock $stacklock; read -u 5 path x y; flock -u $stacklock; [ ${#path} -gt 0 ]; } do
		flock $counterlock
		read -u 10 counter
		echo "${counter}P$(fgrep pos /proc/self/fdinfo/5 | cut -d\	 -f2)" > $CURRENT
		flock -u $counterlock
		#echo "${counter}P$(fgrep pos /proc/self/fdinfo/5 | cut -d\	  -f2)" > $CURRENT
		#echo $counter > $CURRENT
		step=${#path}

#		if [ $step -ne $previousStep ]; then
#			previousStep=$step
#			stackCount=$(wc -l < $STACK)
#			nextStepCounter=$((previousStep != 0 || nextStepCounter == 0? $stackCount : nextStepCounter))
#		fi
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

		computeDoors "$x" "$y" "$path"

		((counter % 10 == 0)) && print "$path" $x $y "${doors}"

#		if hasArrived $x $y; then
#			echo "$proc: Ended (arrived) path: $path"
#			arrived="$step:$path"
#			continue
#		fi
		hasArrived $x $y && { echo "$proc: Ended (arrived) path: $path"; arrived="$step:$path"; continue; }

		nextMove "$path" "$x" "$y" $step
	done

	echo "$proc: No more coords at step=$step"
	echo "$proc: Longest: $arrived"
}

touch $STACK $CURRENT
if [ $(wc -l < $STACK) -eq 0 ]; then
	toStack "S,${start[0]},${start[1]}" 0
fi

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

seqGenerator $counter & 

for proc in $(seq 1 $PROCS); do
	longestPath $((proc - 1)) &
	sleep 5
done

while [ $(jobs | wc -l) -gt 1 ]; do
	wait -n
done

killprocs

echo "fgrep \"Longest:\" "

