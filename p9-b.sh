#!/bin/bash

decompress() {
	# Recurse decompression
	# ..had to use tmp file because of the humongous size of the decompressed data
	# ..could have ignored the data and just do some math, but that would keep me
	# ..from checking the test results...
	local compressedtmp=$(tempfile -p p9b)
	parse "$1" > "$compressedtmp"

	local n
	for ((n=0; n<times; n++)) {
		cat "$compressedtmp"
	}

	rm "$compressedtmp"
}

parse() {
	local input="$1"
	local numchars=""
	local times=""
	local compressed=""
	local compressedtmp=""
	local getting=output
	local c
	local i
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
					decompress "$compressed"
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
		decompress "$compressed"
	fi
}


while read input; do
	parse "$input" | tr -d '[:space:]' > /tmp/p9.out
#	cat /tmp/p9.out
	echo
	wc -c /tmp/p9.out
done
