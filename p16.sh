#!/bin/bash

length=$1
input=$2

TMP=$(tempfile -p p16a)
TMP2=$(tempfile -p p16b)

dragon() {
	cp $TMP $TMP2
	echo >> $TMP
	echo -e "0\c" >> $TMP2
	sed "s/./&\n/g" < $TMP | fgrep -n "" | sort -nr -t: -k1,1 | cut -d: -f2 | tr '01' '10' | tr -d '\n' >> $TMP2
	cp $TMP2 $TMP
}

checksum() {
	echo >> $TMP
	sed -e "s/../&\n/g" < $TMP | sed -e "s/^\(00\|11\)$/1/g" -e "s/^\(01\|10\)$/0/g" | tr -d '\n' > $TMP2
	cp $TMP2 $TMP

	if [ $(($(wc -c < $TMP) % 2)) -eq 0 ]; then
		checksum
		return
	fi

	cat $TMP
	echo
}

echo -e "$input\c" > $TMP
datalen=$(wc -c < $TMP)

while [ $datalen -lt $length ]; do
	echo -e "\r$datalen...\c"
	dragon
	datalen=$(wc -c < $TMP)
done

echo
echo "data(len=$(wc -c < $TMP))"
#cat $TMP
echo >> $TMP
echo "Cutting to $length"
cut -c1-$length < $TMP | tr -d '\n' > $TMP2
cp $TMP2 $TMP
echo "data(len=$(wc -c < $TMP))"
#cat $TMP
echo
echo "checksum:"
checksum $data

rm $TMP $TMP2
