#!/bin/bash

declare sectorsum

count() {
	local -A letters

	local name=$(echo $1 | tr -d '-')

	for letter in $(echo "$name" | sed "s/./& /g"); do
		let "letters[$letter]++"
	done

	declare -p letters | cut -d\' -f2
}

indexOf() {
	eval local -A letters=$1
	local value=$2

	for i in "${!letters[@]}"; do
		if [ "${letters[$i]}" = "$value" ]; then
			echo "$i"
		fi
	done
}

getTopFive() {
	eval local -A letters=$1
	local -A topfive=()
	local i=0

	for value in $(echo ${letters[@]} | tr ' ' '\n' | sort -ru); do
		for letter in $(indexOf "$1" $value); do
			topfive[$((i++))]=$letter
			if [ $i -ge 5 ]; then
				break 2
			fi
		done
	done

	declare -p topfive | cut -d\' -f2
}

compare() {
	eval local -A topfive=$1
	local checksum=$2

	echo -e "   \c"
	local i=0
	for letter in $(echo "$checksum" | sed "s/./& /g"); do
		echo -e " i=$i ck[$i]=$letter topfive[$i]=${topfive[$i]}\c"
		if [ "${topfive[$i]}" != $letter ]; then
			echo " not real"
			return 1
		fi
		let "i++"
	done

	echo " real"
	return 0
}

decrypt() {
	local encname=$(echo "$1" | sed "s/-$//")
	local sector="$2"
	local a=$(printf "%d" "'a'")
	local z=$(printf "%d" "'z'")
	local numletters=$((z - a + 1))
	
	for encletter in $(echo $encname | sed "s/./& /g"); do
		case "$encletter" in
			"-")
				letter=" ";;
			*)
				decval=$(( ( ($(printf "%d" "'$encletter'") - a + sector) % numletters) + a))
				letter=$(printf "\x$(printf "%x" $decval)")
				;;
		esac
		echo -e "$letter\c"
	done
	echo
}

search="northpole object storage"

echo "Enter sequence, finish with crtl+D"
while read encname; do
	name=$(echo "$encname" | sed "s/^\(.*\)-[0-9]*\[[^]]*\]$/\1/")

	if [ "${#name}" -ne "${#search}" ]; then
		echo "   $name (${#name}) <> $search (${#search})"
		continue
	fi
	sector=$(sed "s/^[^0-9]*\([0-9]*\)\[[^]]*\]$/\1/" <<<"$encname")
	checksum=$(sed "s/^[^[]*\[\([^]]*\)\]$/\1/" <<<"$encname")

	echo "name=$name sector=$sector chk=$checksum"

	letters="$(count $name)"
	topfive="$(getTopFive "$letters")"
	
	echo "   letters=$letters topfive=$topfive"
	if compare "$topfive" $checksum; then
		decrypted=$(decrypt $name $sector)
		echo "   '$decrypted'"
		if [ "$decrypted" = "$search" ]; then
			echo $sector
			break
		fi
	fi
done
