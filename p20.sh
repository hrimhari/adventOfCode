#!/bin/bash

INPUT=/tmp/p20.input
BLOCKED=/tmp/p20.blocked
SORTED=/tmp/p20.sorted

sort -n -t- -k1,1 < $INPUT > $SORTED

min=0

echo Generating blocked list...
total=$(wc -l < $INPUT)
count=0
oldIFS="$IFS"
IFS="-"
while read from to;do
	let count++
	((count % 1 == 0? 1 : 0)) && echo -e "\r${count}/${total}: min=$min, ${from}-${to}...\c"
	if [ $min -ge $from ] && [ $min -le $to ]; then
		echo "$min blocked in range ${from}-${to}"
		let "min = to + 1"
	fi
done < $SORTED
IFS="$oldIFS"

echo
echo $min
