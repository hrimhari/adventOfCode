#!/bin/bash

declare -a regexes=('^[^][]*([^][])([^][])\1.*\[[^]]*\2\1\2[^]]*\]' '\[[^]]*([^][])([^][])\1[^]]*\].*\2\1\2[^][]*$' '([^][])([^][])\1[^][]*\[[^]]*\2\1\2[^]]*\]' '\[[^]]*([^][])([^][])\1[^]]*\][^[]*\2\1\2')
declare -a butnots=('^[^][]*([^][])\1\1.*\[[^]]*\1\1\1[^]]*\]' '\[[^]]*([^][])\1\1[^]]*\].*\1\1\1[^][]*$' '([^][])\1\1[^[]*\[[^]]*\1\1\1[^]]*\]' '\[[^]]*([^][])\1\1[^]]*\][^[]*\1\1\1')

count=0
while read ip; do
	echo -e "\n${ip}\c"
	for regex in "${regexes[@]}"; do
		match=$(egrep --color=always "$regex" <<<"$ip")
		if [ $? -eq 0 ]; then
			echo -e ", matches '$regex': $match\c"
			for butnot in "${butnots[@]}"; do
				match=$(egrep --color=always "$butnot" <<<"$ip")
				if [ $? -eq 0 ]; then
					echo -e ", but matches '$butnot': $match\c"
					continue 3
				else
					echo -e " and doesn't match '$butnot'\c"
				fi
			done

			let count++
			break
		else
			echo -e ", no match for '$regex'\c"
		fi
	done
done

echo -e "\n$count"
