#!/bin/bash

NUMBER=$1

PRESENTS1=/tmp/p19.presents
PRESENTS2=${PRESENTS}2

hex=$(printf "%x" $NUMBER)
elfLength=${#hex}
seq 1 $NUMBER | xargs printf "%0${elfLength}x" > $PRESENTS1

DEBUG=$2

computeEta() {
	local nowSeconds=$(date +%s)

	let "etaSeconds = nowSeconds + currentNumber * (nowSeconds - previousSeconds) / (previousNumber - currentNumber), previousNumber = currentNumber, previousSeconds = nowSeconds"
}

previousSeconds=$(date +%s)
previousNumber=$(wc -l < ${PRESENTS1})
etaSeconds=0

while [ $((currentNumber = $(stat --printf="%s" ${PRESENTS1}) / $elfLength)) -gt 1 ]; do
	half=$((currentNumber/2))

	# Copy first block without thief
	if [ $half -gt 1 ]; then
		dd if=$PRESENTS1 of=$PRESENTS2 status=none bs=$((elfLength * (half - 1))) iflag=skip_bytes skip=$elfLength count=1
	else
		> $PRESENTS2
	fi
	[ ${#DEBUG} -ne 0 ] && echo "first block: '$(cat $PRESENTS2)'"

	# Copy last block
	[ $currentNumber -gt 2 ] && dd if=$PRESENTS1 of=$PRESENTS2 status=none conv=notrunc oflag=append iflag=skip_bytes bs=$((elfLength * half)) skip=$((elfLength * (half + 1)))
	[ ${#DEBUG} -ne 0 ] && echo "all blocks: '$(cat $PRESENTS2)'"

	# Move first to last
	dd if=$PRESENTS1 of=$PRESENTS2 status=none bs=$elfLength seek=$((currentNumber - 1)) oflag=append conv=notrunc skip=0 count=1
	[ ${#DEBUG} -ne 0 ] && echo "final: '$(cat $PRESENTS2)'"

	# Switch
	dd if=$PRESENTS2 of=$PRESENTS1 status=none bs=$((elfLength * (currentNumber - 1))) count=1 status=none

	(($currentNumber % 20 == 0 ? 1 : 0)) && computeEta
	(($currentNumber % 1 == 0 ? 1 : 0)) && echo -e "\rcurrent=${currentNumber}\c" && [ $etaSeconds -gt 0 ] && echo -e " (ETA $(date --date="@${etaSeconds}"))...\c"
	[ ${#DEBUG} -ne 0 ] && echo
	[ ${#DEBUG} -ne 0 ] && echo "all: '$(cat $PRESENTS1)'"
done

echo

printf "\n%d\n" "0x$(dd if=$PRESENTS1 bs=$elfLength status=none count=1)"
