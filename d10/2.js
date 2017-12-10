const fs = require('fs')

const parseInput = function() {
	const programs = {}
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'})
		.replace('\n', '')
		.split('')
		.map(item => item.charCodeAt(0))
		.concat([17, 31, 73, 47, 23])
	console.log(`Input: ${lines}`)
	return lines
}

const reverse = function (sequence, pos, length) {
	let count
	console.log(`Reversing from ${pos} for ${length}: ${sequence}`)
	for (count = 0; count < length / 2; count++) {
		const fwPos = (pos + count) % sequence.length
		const bwPos = (pos + length - count - 1) % sequence.length
		console.log(`Swap seq[${fwPos}](${sequence[fwPos]}) with seq[${bwPos}](${sequence[bwPos]})`)
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
}

const hexa = function(sequence) {
	let value = ''

	sequence.forEach(code => {
		value += code.toString(16).padStart(2, '0')
	})
	return value
}

console.log(`Args: ${process.argv}`)
const sequence = Array.from(Array(process.argv[3] && parseInt(process.argv[3]) || 256).keys())
console.log(`Sequence: ${JSON.stringify(sequence)}`)
const lengths = parseInput()

const encrypted = crypt(sequence, lengths)
const hashed = dense(sequence)
const hexaed = hexa(hashed)
console.log(`Result: ${hexaed}`)
