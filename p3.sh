#!/bin/bash

possible=0
while read line;do
	line=$(echo $line | tr -s '[[:space:]]' | sed -e "s/^[[:space:]]//")

	declare -a sides
	read -a sides <<<"$line"

	echo "array: ${sides[@]}"

	isit=1
	for i in $(seq 0 2);do
		i2=$(((i + 1) % 3))
		i3=$(((i2 + 1) % 3))
		
		echo -e "  ${sides[i]}($i) + ${sides[i2]}($i2) = $((${sides[i]} + ${sides[i2]})) > ${sides[i3]}($i3)? \c"

		if [ $((${sides[i]} + ${sides[i2]})) -le ${sides[i3]} ];then
			isit=0
			echo "no"
			break
		fi

		echo "yes"
	done

	let "possible += isit"
done

echo $possible
