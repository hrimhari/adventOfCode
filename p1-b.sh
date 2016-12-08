#!/usr/local/bin/bash

dir=0
x=0
y=0

declare -A dirop=( [R]="+1" [L]="-1" )
declare dirs=( "y=y+" "x=x+" "y=y-" "x=x-" )
declare -A passed

newDir() {
	echo $((($dir $1 + 4) % 4))
}

unsign() {
	echo "$1" | tr -d '-'
}

pass() {
	oldX=$1
	oldY=$2
	newX=$3
	newY=$4
	steps=0
	func_return=""

	for x in $(seq $oldX $newX); do
		for y in $(seq $oldY $newY); do
			echo "   xy=$x,$y passed[$x,$y]=${passed[$x,$y]}" 1>&2
			if ([ $steps -gt 0 ]) && ([ "${passed[$x,$y]}" != "" ]); then
				func_return=$steps
				return
			fi
			passed[$x,$y]="1"
			let "steps++"
		done
	done
}

path=$(echo $* | tr -d ',')

for dirstep in $path; do
	newdir=$(printf "%1.1s" $dirstep)
	steps=$(echo $dirstep | sed "s/^.\([0-9]*\)$/\1/")
	newdirop=${dirop[$newdir]}
	olddir=$dir
	dir=$(newDir $newdirop)

	oldX=$x
	oldY=$y

	let "${dirs[$dir]} $steps"

	pass $oldX $oldY $x $y
	passed=$func_return

	echo "newdir=$newdir steps=$steps newdirop=$newdirop olddir=$olddir dir=$dir oldxy=$oldX,$oldY xy=$x,$y passed=$passed passed[$x,$y]=${passed[$x,$y]}"

	if [ "$passed" != "" ]; then
		break
	fi

done

echo "Distance: $(($(unsign $x) + $(unsign $y)))"
