#!/bin/bash

NUMBER=$1

PRESENTS=/tmp/p19.presents
PRESENTS2=${PRESENTS}2

if [ ! -f $PRESENTS ]; then
	seq 1 $NUMBER > $PRESENTS
fi

while [ $((currentNumber = $(wc -l < $PRESENTS))) -gt 2 ]; do
	half=$((currentNumber/2))

	sed "1{h;d};$((half+1))d;\${G}" < $PRESENTS > $PRESENTS2

	mv $PRESENTS2 $PRESENTS

	(($currentNumber % 10 == 0 ? 1 : 0)) && echo -e "\r${currentNumber}...\c"
done

echo

cut -d: -f1 < $PRESENTS
