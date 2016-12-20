#!/bin/bash

NUMBER=$1

PRESENTS1=/tmp/p19.presents
PRESENTS2=${PRESENTS}2

if [ ! -f $PRESENTS ]; then
	seq 1 $NUMBER > $PRESENTS
fi

pNum=2
pName=PRESENTS

switch() {
	p1=${pName}$((pNum = (pNum * 2)  % 3))
	p2=${pName}$((3 - pNum))
}

switch

while [ $((currentNumber = $(wc -l < ${!p1}))) -gt 2 ]; do
	half=$((currentNumber/2))

	sed "1{h;d};$((half+1))d;\${G}" ${!p1} > ${!p2}

	#mv $PRESENTS2 $PRESENTS
	switch

	(($currentNumber % 1 == 0 ? 1 : 0)) && echo -e "\r${currentNumber}...\c"
done

echo

cut -d: -f1 < $PRESENTS
