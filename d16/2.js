const fs = require('fs')

const s = (programs, number) => {
	number = parseInt(number)
	const removed = programs.splice(programs.length - number, number)
	programs.splice(0, 0, ...removed)
}

const x = (programs, a, b) => {
	const temp = programs[parseInt(a)]
	programs[a] = programs[parseInt(b)]
	programs[b] = temp
}

const p = (programs, a, b) => {
	const posA = programs.indexOf(a)
	const posB = programs.indexOf(b)
	const temp = programs[posA]
	programs[posA] = programs[posB]
	programs[posB] = temp
}

const getPrograms = (numPrograms) => {
	const programs = []
	numPrograms = numPrograms || 16

	for (let i = 0; i < numPrograms; i++) {
		programs.push(String.fromCharCode('a'.charCodeAt(0) + i))
	}
	console.log(`Programs: ${programs}`)
	return programs
}

const dance = (programs, steps) => {
	steps.forEach(step => {
		step[0](programs,step[1],step[2])
	})
	return programs
}

const map = (start, end) => {
	const map = []
	for (let i = 0; i < start.length; i++) {
		map.push(end.indexOf(start[i]))
	}
	return map
}

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'})
		.split(/\n|,/g)
		.filter(line => line != '')
		.map(line => [eval(line.charAt(0)), ...line.substring(1).split('/')])
	return lines
}

const steps = parseInput()

let programs = getPrograms(process.argv[3])
const reference = programs.concat()
let allSequences = {}
allSequences[programs.join('')] = true

const iterations = 1000000000

for (let i = 1; i < iterations; i++) {
	dance(programs, steps)
	if (i < 10 || (i % (iterations / 100) === 0)) {
		process.stdout.write(`${programs.join('')} ${i * 100 / iterations}%...     \r`)
		if (i < 10) process.stdout.write('\n')
	}
	const key = programs.join('')
	if (allSequences[key] === true) {
		console.log(`Looped at ${i}! ${key}`)
		i = iterations - (iterations % i) - 1
		allSequences = {}
	}
	allSequences[key] = true
}

console.log(`\n${programs.join('')}`)
