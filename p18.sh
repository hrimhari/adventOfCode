#!/bin/bash

ROOMLEN=${2:-40}
ROWLEN=0

ROOM=/tmp/p18.room

if [ $1 = "-t" ]; then
	ROOMLEN=10
	set -- .^^.^.^^^^
fi

getTile() {
	local index=$1
	local tempRow=".${previousRow}."
	tempRow=${tempRow:$index:3}

	case "$tempRow" in
		"^^."|".^^"|"^.."|"..^")
			echo -e "^\c";;
		*)
			echo -e ".\c";;
	esac
}

getNextRow() {
	local i

	for ((i = 0; i < ${#previousRow}; i++)) {
		getTile $i
	}
}

countSafe() {
	local row
	local count=$(tr -d '\r\n^' < $ROOM | wc -c)

	echo "Safe tiles: $count"
}

getRoom() {
	local i
	local previousRow=$1
	local nextRow

	echo "$previousRow" > $ROOM

	ROWLEN=${#previousRow}

	for ((i = 2; i <= $ROOMLEN; i++)) {
		((i % 100 == 0? 1 : 0)) && echo -e "\r${i}...\c"
		nextRow="$(getNextRow)"
		echo "$nextRow" >> $ROOM
		previousRow=$nextRow
	}
	echo

	countSafe
}

getRoom $1
