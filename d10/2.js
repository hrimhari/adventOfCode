const fs = require('fs')
const kh = require('./knothash')

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'})
		.replace('\n', '')
	process.argv.length > 3 && console.log(`Input: ${lines}`)
	return lines
}

process.argv.length > 3 && console.log(`Args: ${process.argv}`)
const sequenceSize = process.argv[3] && parseInt(process.argv[3]) || 256
const input = parseInput()

const hexaed = kh.hash(input, sequenceSize)
console.log(`Result: ${hexaed}`)
