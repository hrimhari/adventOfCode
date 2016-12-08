#!/usr/local/bin/bash

dir=0
x=0
y=0

declare -A dirop=( [R]="+1" [L]="-1" )
declare dirs=( "y=y+" "x=x+" "y=y-" "x=x-" )

newDir() {
	echo $((($dir $1 + 4) % 4))
}

unsign() {
	echo "$1" | tr -d '-'
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

	echo "newdir=$newdir steps=$steps newdirop=$newdirop olddir=$olddir dir=$dir oldxy=$oldX,$oldY xy=$x,$y"
done

echo "Distance: $(($(unsign $x) + $(unsign $y)))"
