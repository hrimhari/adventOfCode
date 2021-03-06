const fs = require('fs')

const createGenerator = (start, factor, multiple) => {
	let current = start
	return () => {
		do {
			current = (current * factor) % 2147483647
		} while (current % multiple !== 0)
		return current
	}
}

const mask = (value) => value & 0xFFFF

const loop = (input) => {
	const generators = [
		createGenerator(input[0], 16807, 4),
		createGenerator(input[1], 48271, 8)
	]
	let count = 0

	process.stdout.write('--Gen. A--  --Gen. B--\n')
	for (let iterationsLeft = 5000000; iterationsLeft > 0; iterationsLeft--) {
		count += generators.map(g => g())
			.map(value => {
				if (iterationsLeft > 4999990) {
					process.stdout.write(`${value}`.padStart(10) + '  ')
				}
				return value
			})
			.map(value => mask(value))
			.map(value => {
				if (iterationsLeft > 4999990) {
					process.stdout.write(`${value.toString(2)}`.padStart(16, 0) + '  ')
				}
				return value
			})
			.reduce((acc, value, i) => {
				acc = acc + value * (2*i + -1)
				if (iterationsLeft > 4999990) {
					process.stdout.write(`${acc}`.padStart(6) + '  ')
				}
				return acc
			}, 0) 
			=== 0 ? 1 : 0
		if (iterationsLeft > 4999990) {
			process.stdout.write(`${count}\n`)
		}
	}

	return count
}

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).split('\n').filter(line => line != '').map(line => line.split(' ').pop())
	return lines
}

const input = parseInput()

console.log(`Count: ${loop(input)}`)
