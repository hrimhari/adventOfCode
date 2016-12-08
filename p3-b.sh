#!/bin/bash

declare -a columns
possible=0

echo "Reading lines..."
while read line;do
	line=$(echo $line | tr -s '[[:space:]]' | sed -e "s/^[[:space:]]//")

	declare -a sides
	read -a sides <<<"$line"

	for i in $(seq 0 2);do
		columns[i]="${columns[i]}${sides[i]}"$'\n'
	done
done

input="${columns[@]}"

echo "Reading coluns..."
declare -a sidesmatrix

hds=0
while read side;do
	if [ "$side" = "" ];then continue;fi

	echo "side: $side"
#	hds=$(echo "00$side" | sed "s/^.*\(.\)..$/\1/")
#	side=$(echo "  $side" | sed -e "s/^.*\(..\)$/\1/" -e "s/^0*//")

	sidesmatrix[hds]="${sidesmatrix[hds]}${side}"$'\n'

	echo "hds=$hds, wc=$(echo ${sidesmatrix[hds]} | wc -w): $side"

	if [ $(echo ${sidesmatrix[hds]} | wc -w) -eq 3 ];then
		read -a sides <<<${sidesmatrix[hds]}

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

		sidesmatrix[hds]=""
	fi

done <<<"$input"

echo $possible
