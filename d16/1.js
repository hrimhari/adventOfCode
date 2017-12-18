const fs = require('fs')

const s = (programs, number) => {
	number = parseInt(number)
	programs.unshift(...programs.slice(-number))
	programs.splice(programs.length - number, number)
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

const dance = (steps, numPrograms) => {
	const programs = []
	numPrograms = numPrograms || 16

	for (let i = 0; i < numPrograms; i++) {
		programs.push(String.fromCharCode('a'.charCodeAt(0) + i))
	}

	console.log(`Programs: ${programs}`)

	steps.forEach(step => {
		console.log(step)
		eval(`${step[0]}(programs,'${step.slice(1).join('\',\'')}')`)
	})
	return programs
}

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'})
		.split(/\n|,/g)
		.filter(line => line != '')
		.map(line => [line.charAt(0), ...line.substring(1).split('/')])
	return lines
}

const steps = parseInput()

console.log(dance(steps, process.argv[3]).join(''))
