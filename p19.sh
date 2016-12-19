#!/bin/bash

NUMBER=$1

PRESENTS=/tmp/p19.presents
PRESENTS2=${PRESENTS}2

seq 1 $NUMBER | sed "s/$/:1/" > $PRESENTS

while [ $((currentNumber=$(wc -l < $PRESENTS))) -gt 1 ]; do
	sed "1~2N;s/\n/:/" < $PRESENTS > $PRESENTS2
	if [ $((currentNumber % 2)) -eq 1 ]; then
		last=$(tail -1 $PRESENTS2):$(head -1 $PRESENTS2)
		tail -n +2 $PRESENTS2 | head -n -1 > $PRESENTS
		echo $last >> $PRESENTS
	else
		mv $PRESENTS2 $PRESENTS
	fi
	echo -e "\r${currentNumber}...\c"
done

echo

cut -d: -f1 < $PRESENTS
