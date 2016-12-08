#!/bin/bash

declare -a regexes=('^[^][]*([^][])([^][])\1.*\[[^]]*\2\1\2[^]]*\]' '\[[^]]*([^][])([^][])\1[^]]*\].*\2\1\2[^][]*$' '([^][])([^][])\1[^][]*\[[^]]*\2\1\2[^]]*\]' '\[[^]]*([^][])([^][])\1[^]]*\][^[]*\2\1\2')
declare -a butnots=('^[^][]*([^][])\1\1.*\[[^]]*\1\1\1[^]]*\]' '\[[^]]*([^][])\1\1[^]]*\].*\1\1\1[^][]*$' '([^][])\1\1[^[]*\[[^]]*\1\1\1[^]]*\]' '\[[^]]*([^][])\1\1[^]]*\][^[]*\1\1\1')

getAbas() {
	local seq="$1"
	local -a abas=()

	for ((i = 0; i < ${#seq} - 2; i++)) {
		if ([ ${seq:$i:1} = ${seq:$((i+2)):1} ]) && ([ ${seq:$i:1} != ${seq:$((i+1)):1} ]); then
			aba=${seq:$i:3}
			echo "   new aba/bab: $aba" >&2
			abas[${#abas[@]}]=$aba
		fi
	}

	echo "${abas[@]}"
}

getExpectedBabs() {
	eval local -a abas=($*)
	local -a babs=()

	for aba in ${abas[@]}; do
		bab=${aba:1:1}${aba:0:1}${aba:1:1}
		echo "   new expected bab: $bab" >&2
		babs[${#babs[@]}]=$bab
	done

	echo "${babs[@]}"
}

isSsl() {
	eval local -a expectedBabs=$1
	eval local -a babs=$2

	for bab in ${babs[@]}; do
		if fgrep -q "$bab" <<<"${expectedBabs[@]}"; then
			return 0
		fi
	done

	return 1
}

count=0
while read ip; do
	echo "${ip}:"

	supernets=($(echo "$ip" | sed -e "s/\[[^]]*\]/ /g"))
	hypernets=($(echo "$ip" | sed -e "s/\(^\|\]\)[^][]*\(\[\|$\)/ /g"))

	echo "   supernets: ${supernets[@]}"
	echo "   hypernets: ${hypernets[@]}"
	abas=()
	babs=()
	expectedBabs=()

	for supernet in ${supernets[@]}; do
		abas+=($(getAbas $supernet))
	done

	echo "   abas: ${abas[@]}"

	expectedBabs=($(getExpectedBabs "${abas[@]}"))

	echo "   expected babs: ${expectedBabs[@]}"

	for hypernet in ${hypernets[@]}; do
		babs[${#babs[@]}]=$(getAbas $hypernet)
	done

	echo "   babs: ${babs[@]}"

	if isSsl "${expectedBabs[@]}" "${babs[@]}"; then
		echo "   SSL"
		let count++
	else
		echo "   Not SSL"
	fi
done

echo "$count"
