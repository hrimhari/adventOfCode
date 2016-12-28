#!/bin/bash

TEST=0

if [ $TEST -eq 1 ]; then
	INPUT=/tmp/p25.test
else
	INPUT=/tmp/p25.improved
fi
TMP1=${INPUT}1
TMP2=${INPUT}2

let a=${1:-1} b=0 c=0 d=0
pc=1

nop() {
	:
}

tgl() {
	x=$1
	newPc=$((pc + ${!x}))
	echo "pc=$pc, x=$x, newPc=$newPc"
	echo "<Enter>"
	read dummy

	sed "$newPc{s/^inc/D/;s/^\(dec\|tgl\)/inc/;s/^D/dec/;s/^jnz/C/;s/^\(cpy\)/jnz/;s/^C/cpy/}" $TMP1 > $TMP2
	mv $TMP2 $TMP1

}

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

mul() {
	x=$1
	y=$2

	let "${x}*=${y}"
}

div() {
	x=$1
	y=$2

	let "${x}/=${y}"
}

mod() {
	x=$1
	y=$2

	let "${x}%=${y}"
}

jnz() {
	x=$1
	y=$2

	case "$x" in
		a|b|c|d)
			x=${!x};;
	esac
			
	if [ $x -ne 0 ]; then
		let "pc += $y, pc < 1? pc = 1 : pc, pc--"
	fi
}

out() {
	x=$1

	case "$x" in
		a|b|c|d)
			x=${!x};;
	esac

	echo "Out: $x"
}

cp $INPUT $TMP1

while read ins parms <<<"$(sed -n "${pc}p" $TMP1)"; do
	if [ "$ins" = "" ]; then break; fi

	echo "pc=$pc a=$a b=$b c=$c d=$d: $ins $parms"

	$ins $parms
	if [ $b -ne 0 ] && [ $c -ne 0 ]; then
		let "min=b*c, odd=1, multi=0"
		while [ $multi -lt $min ]; do
			let "multi=(multi*2)+odd, odd=1-odd"
		done

		echo "$((multi-min))"
		exit 0
	fi

	let pc++

done

echo "a=$a"
