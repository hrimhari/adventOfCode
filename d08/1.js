const fs = require('fs')

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).split('\n').filter(line => line != '').map(line => {
		line = line.split(' ')
		line = {
			ins:line[1],
			r1:line[0],
			r2:line[2],
			cond:line[5],
			cr:line[4],
			cv:line[6]
		}
		return line
	})
	return lines
}

const registers = {_highest:0}

const getRegister = function(name, registers) {
	return registers[name] || 0
}

const registerHighest = function(value, registers) {
	const cur = registers._highest

	if (value > cur) {
		registers._highest = value
		console.log(`new highest: ${value}`)
	}
}

const inc = function(register, value, registers) {
	const oldv = getRegister(register, registers)
	registers[register] = oldv + value
	console.log(`inc: ${register}=${oldv}+${value}=${registers[register]}`)
//	registerHighest(registers[register], registers)
}
const dec = function(register, value, registers) {
	const oldv = getRegister(register, registers)
	registers[register] = oldv - value
	console.log(`dec: ${register}=${oldv}-${value}=${registers[register]}`)
//	registerHighest(registers[register], registers)
}

const runOneLine = function(line, registers) {
	console.log(`Running: ${JSON.stringify(line)}`)
	const crvalue = getRegister(line.cr, registers)

	if (eval(`${crvalue} ${line.cond} ${line.cv}`)) {
		eval(`${line.ins}('${line.r1}', ${line.r2}, registers)`)
	}
}

const findHighest = function(registers) {
	const names = Object.keys(registers)
	names.sort((a, b) => registers[a] - registers[b])

	console.log(`Registers: ${JSON.stringify(names)}`)
	console.log(`Highest: ${names[names.length - 1]}=${registers[names[names.length - 1]]}`)
	return registers[names[names.length - 1]]
}

const program = parseInput()

program.forEach(line => runOneLine(line, registers))

findHighest(registers)
