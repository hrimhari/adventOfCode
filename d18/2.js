const fs = require('fs')

let sndReg
let pc = 0
const processes = []
const reg = {}

const snd = function(X) {
	X = this.reg[X] || X
	processes[1 - this.id].queue.push(X)
	processes[1 - this.id].locked = false
	this.sent++
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
	if (this.queue.length === 0) {
		this.locked = true
 		return true
	}
	this.reg[X] = this.queue.shift()
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
		reg: {p: processes.length}
	})
}

const run = (program) => {
	createProcess()
	createProcess()
	console.log(`Processes: ${JSON.stringify(processes)}`)
	console.log(`Program length: ${program.length}`)
	let running = processes[0]
	for (; processes.some(p => (!p.locked && (p.pc < program.length))); running.pc++) {
		if (running.locked) {
			running.pc--
			running = processes[1-running.id]
			running.pc--
			continue
		}
		const line = program[running.pc]
//		console.log(`${line}: ${JSON.stringify(running)}`)
		line[0].call(running, line[1], line[2])
	}

	console.log(`Processes: ${JSON.stringify(processes)}`)
	console.log(`Sent: 0:${processes[0].sent}, 1:${processes[1].sent}`)
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
