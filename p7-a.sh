#!/bin/bash

count=0
while read ip; do
	if ! egrep -q '(.)(.)\2\1' <<<"$ip"; then
		echo "   no match: $ip"
	elif egrep -q "\[[^]]*([^]])([^]])\2\1[^]]*\]" <<<"$ip" && ! egrep -q "\[[^]]*([^]])\1\1\1[^]]*\]" <<<"$ip"; then
		echo "   ABBA in braquets: $ip"
	elif sed "s/[.*]//" <<<"$ip" | egrep "(.)\1\1\1"; then
		echo "   not ABBA: $ip"
	else
		let count++
	fi
done

echo $count
