#!/bin/bash

INPUT=/tmp/p20.input
BLOCKED=/tmp/p20.blocked
SORTED=/tmp/p20.sorted

sort -n -t- -k1,1 < $INPUT > $SORTED

min=0
ipCount=0

total=$(wc -l < $INPUT)
count=0
oldIFS="$IFS"
IFS="-"
while read from to;do
	let count++
	((count % 1 == 0? 1 : 0)) && echo -e "\r${count}/${total}: min=$min, ${from}-${to}...\c"
	if [ $min -ge $from ] && [ $min -le $to ]; then
		echo " $min blocked in range ${from}-${to}"
		min=$((to + 1))
	elif [ $min -lt $from ]; then
		let "ipCount+=from - min"
		let "min = to + 1"
		echo " new count: $ipCount"
	fi
done < $SORTED
IFS="$oldIFS"

echo
echo $min $ipCount
