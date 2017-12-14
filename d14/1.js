const fs = require('fs')
const kh = require('../d10/knothash')

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).split('\n').shift(line => line != '')
	return lines
}

const disk = function(input) {
	const grid = []

	for (let i = 0; i < 128; i++) {
		const hash = kh.hash(`${input}-${i}`)
		const hexaNibbles = hash.split('')
		const bits = hexaNibbles.map(n => parseInt(n, 16).toString(2).padStart(4, '0')).join('').split('')
		grid[i] = bits
	}
	return grid
}

const printDisk = function(disk) {
	for (let i = 0; i < Math.min(10, disk.length); i++) {
		console.log(`${JSON.stringify(disk[i]).substr(0,70)}...`)
	}
}

const count = function(disk) {
	const result = disk.reduce((acc, line) => acc + line.filter(bit => bit === '1').length, 0)
	return result
}

const input = parseInput()
const grid = disk(input)
printDisk(grid)
console.log(`Count: ${count(grid)}`)
