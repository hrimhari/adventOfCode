#!/bin/bash

INPUT=/tmp/p21.input

if [ "$2" != "" ]; then
	INPUT=/tmp/p21.test.input
fi

buffer=$1

swap_position() {
	local a=$1
	local b=$2

	if [ $a -gt $b ]; then
		b=$1
		a=$2
	fi

	buffer="${buffer:0:$a}${buffer:$b:1}${buffer:$((a+1)):$((b - a - 1))}${buffer:$a:1}${buffer:$((b+1))}"
}

swap_letter() {
	local a=$1
	local b=$2

	buffer="$(echo "$buffer" | tr "${a}${b}" "${b}${a}")"
}

reverse_positions() {
	local a=$1
	local b=$2

	if [ $a -gt $b ]; then
		b=$1
		a=$2
	fi

	buffer="${buffer:0:$a}$(echo "${buffer:$a:$((b - a + 1))}" | rev)${buffer:$((b+1))}"
}

rotate_right() {
	local a=$(($1 % ${#buffer}))

	[ $a -eq 0 ] && return

	buffer="${buffer:$a}${buffer:0:$a}"
}

rotate_left() {
	local a=$(($1 % ${#buffer}))

	[ $a -eq 0 ] && return

	buffer="${buffer: -$a}${buffer:0:$((${#buffer} - a))}"
}

rotate_position() {
	local l=$1
	local index=$(($(expr index "$buffer" "$l") - 1))
	local target

	case "$index" in
		2) target=4;;
		4) target=5;;
		6) target=6;;
		0) target=7;;
		7) target=3;;
		5) target=2;;
		3) target=1;;
		1) target=0;;
	esac
	if [ $target -gt $index ]; then
		((index = target - index))
		# actually right
		rotate_left $index
	else
		((index -= target))
		# actually left
		rotate_right $index
	fi

}

move_position() {
	local a=$2
	local b=$1
	local letter=${buffer:$a:1}

	buffer=${buffer:0:$a}${buffer:$((a+1))}
	buffer=${buffer:0:$b}${letter}${buffer:$b}
}

while read cmd params; do
	echo "Will run $cmd with params $params"
	$cmd $params
done <<<"$(sed -e "s/\( with position\| of letter\| steps?\| to position\| with letter\| through\| based on\)//g" -e "s/ /_/" $INPUT | fgrep -n "" | sort -n -r -t: -k1,1 | cut -d: -f2-)"

echo $buffer
