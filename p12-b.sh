#!/bin/bash

let a=0 b=0 c=1 d=0
pc=1

cpy() {
	x=$1
	y=$2

	let "$y = $x"
}

inc() {
	x=$1

	let "${x}++"
}

dec() {
	x=$1
	let "${x}--"
}

add() {
	x=$1
	y=$2

	let "${x}+=${y}"
}

jnz() {
	x=$1
	y=$2

	if [ ${!x} -ne 0 ]; then
		let "pc += $y, pc < 1? pc = 1 : pc, pc--"
	fi
}

while read ins parms <<<"$(sed -n "${pc}p" < $1)"; do
	if [ "$ins" = "" ]; then break; fi

	echo "pc=$pc a=$a b=$b c=$c d=$d: $ins $parms"
	$ins $parms
	let pc++
done

echo "a=$a"
