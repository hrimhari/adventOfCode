#!/usr/local/bin/bash

x=1
y=1
sequence=""

declare -A dirs=( [U]="y==0?0:y--" [R]="x==2?2:x++" [D]="y==2?2:y++" [L]="x==0?0:x--" )

newDir() {
	let "${dirs[$1]}"
}

button() {
	echo $(((y * 3) + x + 1))
}

for buttonpath in $*; do
	for buttonstep in $(echo $buttonpath | sed 's/./&\'$'\n/g'); do
		oldX=$x
		oldY=$y
		newDir $buttonstep
		echo -e "step=$buttonstep oldxy=$oldX,$oldY xy=$x,$y \c"
	done

	echo "button=$(button)"
	sequence="${sequence}$(button)"
done

echo $sequence
