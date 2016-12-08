#!/bin/bash

scan() {
	in=$1
	indices="$2"
	local -a password=()
	for i in $indices; do
		hash=$(echo -e "${in}$i\c" | md5sum)
	
		firstfive=${hash:0:5}
	
		if [ $firstfive = "00000" ]; then
			found=${hash:6:1}
			pos=${hash:5:1}
			ignore="no"

			if [ "${pos//[0-9]}" != "" ]; then
				ignore="pos NaN"
			elif [ $pos -gt 7 ]; then
				ignore="pos>7"
			elif [ "${password[$pos]}" != "" ]; then
				ignore="password[$pos]=${password[$pos]}"
			fi

			echo "  pos=${pos} found=${found} ignore=$ignore" >&2

			if [ "$ignore" != "no" ]; then
				continue
			fi

			password[$pos]=$found
		else
			echo "Bad hash for ${i}: $hash" >&2
		fi
	
		if [ ${#password[@]} -eq 8 ]; then
			break
		fi
	done

	echo "${password[@]}" | tr -d ' '
}


scan $1 "$2"
