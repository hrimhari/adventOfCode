#!/bin/bash

declare -A p0=()
declare -A p1=()
declare -A p2=()
declare -A p3=()
declare -A p4=()
declare -A p5=()
declare -A p6=()
declare -A p7=()

count() {
	local op=""
	for ((i = 0; i < 8; i++)) {
		eval op=\"p${i}[${1:$i:1}]++\"
		echo "op=$op"
		let "$op"
		eval declare -p p${i}
	}
}

indexOf() {
	set +xv
	eval local -A letters=$1
	local value=$2
	for i in "${!letters[@]}"; do
		if [ "${letters[$i]}" = "$value" ]; then
			echo "$i"
		fi
	done
	set -xv
}

getMessage() {
	set -xv
	local message=""
	local -A letters=()
	for ((i = 0; i < 8; i++)) {
		eval letters=$(declare -p p${i} | cut -d\' -f2)
		topval=$(echo "${letters[@]}" | tr ' ' '\n' | sort -du | head -1)
		topletter=$(indexOf "$(declare -p letters | cut -d\' -f2)" $topval)
		message+=$topletter
	}

	echo $message
}

echo "Enter sequence, finish with crtl+D"
while read encname; do
	count $encname
done

getMessage
