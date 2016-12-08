#!/bin/bash

declare -A buttons=( [02]="1" [11]="2" [12]="3" [13]="4" [20]="5" [21]="6" [22]="7" [23]="8" [24]="9" [31]="A" [32]="B" [33]="C" [42]="D" )
declare -A dirops=( [U]='y==0||${#buttons[$((y-1))$x]}==0?y:y--' [R]='x==4||${#buttons[$((x+1))$y]}==0?x:x++' [D]='y==4||${#buttons[$((y+1))$x]}==0?y:y++' [L]='x==0||${#buttons[$y$((x-1))]}==0?x:x--' )

x=0
y=2
sequence=""
while read line; do
	if [ "$line" = "" ];then continue;fi

	echo "steps: $line"
	echo -e "   \c"
	steps=$(sed 's/./&\'$'\n/g' <<<"$line")

	for step in $steps; do
		oldX=$x
		oldY=$y
		eval let \"${dirops[$step]}\"
		echo -e "oldYX=$oldY,$oldX yx=$y,$x step=$step dirop='${dirops[$step]}'; \c"
	done

	button="${buttons[$y$x]}"

	sequence="${sequence}${button}"

	echo "button=$button"
done <<<"$1"

echo "$sequence"
