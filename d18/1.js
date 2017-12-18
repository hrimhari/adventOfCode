/*
Back-ported from 2.js as I forgot to change files between parts -_-
*/
const fs = require('fs')

let sndReg
let pc = 0
const processes = []
const reg = {}

const snd = function(X) {
	X = this.reg[X] || X
	this.sndReg = X
}

const set = function (X, Y) {
	Y = this.reg[Y] || Y
	this.reg[X] = parseInt(Y)
}

const add = function(X, Y) {
	Y = this.reg[Y] || Y
	this.reg[X] += parseInt(Y)
}

const mul = function(X, Y) {
	Y = this.reg[Y] || Y
	this.reg[X] *= parseInt(Y)
}

const mod = function(X, Y) {
	Y = this.reg[Y] || Y
	this.reg[X] = this.reg[X] % Y
}

const rcv = function(X) {
	this.reg[X] && (this.reg[X] = this.sndReg)
	if (this.reg[X] != 0) {
		console.log(`Recover: ${this.reg[X]}`)
		process.exit(0)
	}
}

const jgz = function(X, Y) {
	X = this.reg[X] || X
	Y = this.reg[Y] || Y
	if (X > 0) {
		this.pc += Y - 1
	}
}

const createProcess = () => {
	processes.push({
		id: processes.length,
		queue: [],
		pc: 0,
		sent: 0,
		sndReg: 0,
		reg: {}
	})
}

const run = (program) => {
	createProcess()
	console.log(`Processes: ${JSON.stringify(processes)}`)
	console.log(`Program length: ${program.length}`)
	let running = processes[0]
	for (; processes.some(p => (!p.locked && (p.pc < program.length))); running.pc++) {
		const line = program[running.pc]
		line[0].call(running, line[1], line[2])
	}

	console.log(`Processes: ${JSON.stringify(processes)}`)
	console.log('No recover :(')
}

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).split('\n').filter(line => line != '')
		.map(line => line.split(' '))
		.map(line => [eval(line[0]), line[1], line[2]])
	return lines
}

const program = parseInput()
run(program)
