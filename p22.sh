#!/bin/bash

magic="$1"
INPUT=/tmp/p22.input
OUTPUT=/tmp/p22.${magic}.viable

CLEANED=/tmp/p22.${magic}.cleaned
SORTUSED=/tmp/p22.${magic}.sused
SORTAVAIL=/tmp/p22.${magic}.savail

fgrep dev/grid $INPUT | tr -s ' ' | tr -d 'T' > $CLEANED

sort -n -t\  -k3,3 $CLEANED | fgrep -n "" | tr ':' ' ' > $SORTUSED
sort -n -t\  -k4,4 $CLEANED | fgrep -n "" | tr ':' ' ' > $SORTAVAIL

exec 5<$SORTUSED 6<$SORTAVAIL

availLine=0
availNode=""
availSize=-1
usedLine=0
usedNode=""
usedSize=""

readUsed() {
read -u 5 usedLine usedNode t1 usedSize t2
return $?
}

readAvail() {
read -u 6 availLine availNode t1 t2 availSize t3
return $?
}

> $OUTPUT

while readUsed; do
	echo "Read used '$usedLine' '$usedSize'"

	if [ $usedSize -eq 0 ]; then
		echo "Skip empty"
		continue
	fi

	while [ $availSize -lt $usedSize ] && readAvail; do
		echo "Read available '$availLine' '$availSize'"
	done

	if [ "$availLine" = "" ]; then
		break
	fi

	echo "'$usedNode' '$usedLine' '$usedSize' / '$availNode' '$availLine' '$availSize'"
	sed -n "$availLine,"'$'"{s,$, $usedLine $usedNode $usedSize,p}" $SORTAVAIL | egrep -v "$usedNode .* $usedNode" >> $OUTPUT
done

wc -l $OUTPUT
