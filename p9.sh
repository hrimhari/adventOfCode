#!/bin/bash

decompress() {
	input="$1"
	numchars=""
	times=""
	compressed=""
	getting=output
	for ((i=0; i<${#input}; i++)) {
		c=${input:$i:1}

		case "$getting" in
			"output")
				if [ $c = "(" ]; then
					numchars=""
					times=""
					compressed=""
					getting=numchars
				else
					echo -e "$c\c"
				fi
				;;
			"numchars")
				if [ $c = "x" ]; then
					getting=times
				else
					numchars+=$c
				fi
				;;
			"times")
				if [ $c = ")" ]; then
					getting=compressed
				else
					times+=$c
				fi
				;;
			"compressed")
				if [ $((numchars--)) -eq 0 ]; then
					eval printf \"$compressed%.0s\" {1..$times}
					getting=output
					# Current could be output but also marker. Let's repeat the pass
					let i--
				else
					compressed+=$c
				fi
				;;
		esac
	}

	if [ $getting = "compressed" ]; then
		eval printf \"$compressed%.0s\" {1..$times}
	fi
}


while read input; do
	decompress "$input" | tr -d '[:space:]' > /tmp/p9.out
	cat /tmp/p9.out
	echo
	wc -c /tmp/p9.out
done
