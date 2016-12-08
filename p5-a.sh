#!/bin/bash

TMP=$(tempfile)

echo "TMP=$TMP"

scan() {
	in=$1
	core=$2
	cores=$3
	password=""
	for ((i=$core - 1;; i += $cores)) {
		(((i - $core + 1) % 500)) || echo -e "                                        \r$core ${password}($i)\r\c" >&2
		hash=$(echo -e "${in}$i\c" | md5sum)
	
		firstfive=${hash:0:5}
	
		if [ $firstfive = "00000" ]; then
			found=${hash:5:1}
			password+=$found
			echo "$i $found" >> $TMP
		fi
	
		if [ ${#password} -eq 8 ]; then
			break
		fi
	}
}

for core in $(seq 1 $2); do
	scan $1 $core $2 &
done

while [[ $(wc -l < $TMP) -lt 8 ]]; do
	sleep 10
done

while kill %-; do
	:
done

sort -t\  -k1,1 $TMP
