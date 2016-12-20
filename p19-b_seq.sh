#!/bin/bash

NUMBER=$1

index=0
limit=1
odd=0
result=0

while [ $((++index)) -le $NUMBER ]; do

	if [ $result -eq $limit ]; then
		let "limit*=3, local=1, result=0"
	fi
	let "odd = ( limit > 1 && result >= limit / 3? 1 : 0 ), result += 1 + odd"
	echo -e "\r${index}...\c"
done

echo
echo $result
