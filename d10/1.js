const fs = require('fs')

const parseInput = function() {
	const programs = {}
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).replace(/\s/g, '').split(',').filter(line => line != '').map(item => parseInt(item))
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

const crypt = function(sequence, lengths) {
	let skip = 0
	let pos = 0

	lengths.forEach(length => {
		pos = reverse(sequence, pos, length) + skip++
	})
}

console.log(`Args: ${process.argv}`)
const sequence = Array.from(Array(process.argv[3] && parseInt(process.argv[3]) || 256).keys())
console.log(`Sequence: ${JSON.stringify(sequence)}`)
const lengths = parseInput()

const encrypted = crypt(sequence, lengths)
console.log(`Multiply: ${sequence[0] * sequence[1]}`)
