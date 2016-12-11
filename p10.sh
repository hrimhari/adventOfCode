#!/bin/bash

instructions="$(echo "$1" | sed -e "/value/s/goes to bot //" -e "/^bot/s/ \(gives low\|and high\) to//g")"

valueInput="$(echo "$instructions" | fgrep value)"
botInput="$(echo "$instructions" | grep "^bot")"

declare -A botInstructions=()
declare -a botVals=()
declare -a output=()

level=""

while read botbot botNum instruction; do
	echo "bot $botNum <- $instruction" >&2
	botInstructions[$botNum]="$instruction"
done <<<"$botInput"

output() {
	local val="$1"
	local outputNum="$2"

	echo "${level}output $outputNum got $val" >&2

	output[$outputNum]=$val
}

bot() {
	local newVal="$1"
	local botNum="$2"
	local lowVal
	local highVal
	local lowDest
	local lowDestNum
	local highDest
	local highDestNum

	level+=".."

	echo "${level}bot $botNum got $newVal" >&2

	if [ ${#botVals[$botNum]} -gt 0 ]; then
		read lowVal highVal <<<"$(echo "${botVals[$botNum]}"$'\n'"$newVal" | sort -n | tr '\n' ' ')"

		echo "${level}bot $botNum examines $lowVal $highVal and runs ${botInstructions[$botNum]}" >&2

		read lowDest lowDestNum highDest highDestNum <<<"${botInstructions[$botNum]}"

		$lowDest $lowVal $lowDestNum
		$highDest $highVal $highDestNum

		echo "${level}bot $botNum done" >&2
	else
		botVals[$botNum]="$newVal"
	fi
	level=${level:2}
}


value() {
	local val="$1"
	local botVal="$2"

	bot $val $botVal
}

while read valuevalue valueNum botNum; do
	echo "value $valueNum $botNum" >&2
	value $valueNum $botNum
done <<<"$valueInput"

echo "output[0]*output[1]*output[2]=$((output[0]*output[1]*output[2]))" >&2

