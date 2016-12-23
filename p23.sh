#!/bin/bash

TEST=0

if [ $TEST -eq 1 ]; then
	INPUT=/tmp/p23.test
else
	INPUT=/tmp/p23.input
fi
TMP1=${INPUT}1
TMP2=${INPUT}2

let a=7 b=0 c=0 d=0
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

jnz() {
	x=$1
	y=$2

	if [ ${!x} -ne 0 ]; then
		let "pc += $y, pc < 1? pc = 1 : pc, pc--"
	fi
}

cp $INPUT $TMP1

while read ins parms <<<"$(sed -n "${pc}p" $TMP1)"; do
	if [ "$ins" = "" ]; then break; fi

	echo "pc=$pc a=$a b=$b c=$c d=$d: $ins $parms"
	$ins $parms
	let pc++
done

echo "a=$a"
