const fs = require('fs')

const lengths = function(input) {
	return input.split('')
		.map(item => item.charCodeAt(0))
		.concat([17, 31, 73, 47, 23])
}

const reverse = function (sequence, pos, length) {
	let count
	process.argv.length > 3 && console.log(`Reversing from ${pos} for ${length}: ${sequence}`)
	for (count = 0; count < length / 2; count++) {
		const fwPos = (pos + count) % sequence.length
		const bwPos = (pos + length - count - 1) % sequence.length
		process.argv.length > 3 && console.log(`Swap seq[${fwPos}](${sequence[fwPos]}) with seq[${bwPos}](${sequence[bwPos]})`)
		const temp = sequence[fwPos]
		sequence[fwPos] = sequence[bwPos]
		sequence[bwPos] = temp
	}
	return (pos + length) % sequence.length
}

const dense = function(sequence) {
	const hash = Array.from(Array(16).keys(), () => 0)
	for (let block = 0; block < 16; block++) {
		for (let pos = 0; pos < 16; pos++) {
			hash[block] ^= sequence[block*16 + pos]
		}
	}
	process.argv.length > 3 && console.log(`Dense: ${JSON.stringify(hash)}`)
	return hash
}

const crypt = function(sequence, lengths) {
	let skip = 0
	let pos = 0

	for (var run = 0; run < 64; run++) {
		lengths.forEach(length => {
			pos = reverse(sequence, pos, length) + skip++
		})
	}
	return sequence
}

const hexa = function(sequence) {
	let value = ''

	process.argv.length > 3 && console.log(`Hexing: ${sequence}`)
	sequence.forEach(code => {
		value += code.toString(16).padStart(2, '0')
	})
	return value
}

const sequence = function(size) {
	return Array.from(Array(parseInt(size) || 256).keys())
}

module.exports = { hash: function(input, sequenceSize) {
	const encrypted = crypt(sequence(sequenceSize), lengths(input))
	const hashed = dense(encrypted)
	const hexaed = hexa(hashed)
	return hexaed
}}
