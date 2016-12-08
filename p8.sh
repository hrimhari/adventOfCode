#!/bin/bash

declare -a r0=()
declare -a r1=()
declare -a r2=()
declare -a r3=()
declare -a r4=()
declare -a r5=()

w=50
h=6

rect() {
	a=$1
	b=$2

	echo "rect $a $b"
	for ((y=0; y<b && y<h; y++)) {
		row=r$y
		for ((x=0; x<a && x<w; x++)) {
			setcmd="${row}[$x]=1"
			eval "$setcmd"
		}
	}
}

rotateRow() {
	row=r$1
	shift=$(($2 % w))

	echo "rotrow $row $shift"

	local -a temprow=()

	for ((x=0; x<w; x++)) {
		shiftstep=$(( (x + shift) % w ))
		let "temprow[shiftstep] = ${row}[x]"
	}

	for ((x=0; x<w; x++)) {
		let "${row}[x] = temprow[x]"
	}
}

rotateColumn() {
	column=$1
	shift=$(($2 % h))

	echo "rotcol $column $shift"

	local -a tempcol=()

	for ((y=0; y<h; y++)) {
		shiftstep=$(( (y + h - shift) % h))
		eval tempcol[$y]='${'r${shiftstep}[$column]'}'
	}

	for ((y=0; y<h; y++)) {
		let "r${y}[$column] = tempcol[$y]"
	}
}

print() {
	count=0
	for ((y=0; y<h; y++)) {
		row=r${y}
		for ((x=0; x<w; x++)) {
			eval pixel=\$\{${row}'[$x]'\}
			let "count += pixel"
			echo -e "$(echo $pixel | sed -e "s/^\(0\|\)$/./" -e "s/1/#/")\c"
		}
		echo
	}

	echo $count
}

while read command; do
	case "$command" in
		"rect "*)
			parms=$(echo "$command" | cut -d\  -f2)
			x=$(echo "$parms" | cut -dx -f1)
			y=$(echo "$parms" | cut -dx -f2)
			rect $x $y
			;;
		"rotate column "*|"rotate row "*)
			parms=$(echo "$command" | cut -d= -f2)
			ref=$(echo "$parms" | cut -d\  -f1)
			steps=$(echo "$parms" | cut -d\  -f3)
			realcmd=$(echo "$command" | cut -d\  -f1-2 | sed -e "s/ row/Row/" -e "s/ column/Column/")

			${realcmd} $ref $steps
			;;
	esac
done

print
