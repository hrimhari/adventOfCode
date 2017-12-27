/*
Directions: 0, 1, 2, 3

       0
       Up
       ^   R
   L   |   i
 3 e <-+-> g 2
   f   |   h
   t   v   t
      Down
       1

Positions: [x, y]

*/
const fs = require('fs')

const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).split('\n').filter(line => line != '')
	return lines
}

const findStart = (diagram) => {
	const x = diagram[0].indexOf('|')
	return [x, 0]
}

const whatAt = (pos, diagram) => {
	return (diagram[pos[1]] || '').charAt(pos[0])
}

const within = (pos, diagram) => {
	return pos[1] >= 0 && pos[1] < diagram.length
		&& pos[0] >= 0 && pos[0] < diagram[pos[1]].length
}

const nextDirection = (dir, pos, diagram) => {
	const newDirs = [
		[2, 3],
		[2, 3],
		[0, 1],
		[0, 1]
	]
	const newDir = newDirs[dir].find(d => {
		const nextPos = walk(pos, d)
		return within(nextPos, diagram) && whatAt(nextPos, diagram) != ' '
	})
	process.stdout.write(`[New dir: ${newDir}]`)
	return newDir
}

const walk = (pos, dir) => {
	const dirs = [
		(pos) => pos[1]--,//up
		(pos) => pos[1]++,//down
		(pos) => pos[0]++,//right
		(pos) => pos[0]-- //left
	]

	const newPos = pos.concat()
	dirs[dir](newPos)
	return newPos
}

const loop = (diagram) => {
	let pos = findStart(diagram)
	const letters = []
	let dir = 1
	
	while (dir !== undefined) {
		process.argv[2] && print(pos, dir, diagram)
		let nextPos = walk(pos, dir)
		const nextChar = whatAt(nextPos, diagram) || ' '

		if (nextChar === ' ') {
			process.stdout.write('[Change direction]')
			dir = nextDirection(dir, pos, diagram)
			continue
		}
		if (['+', '|', '-'].indexOf(nextChar) < 0) {
			process.stdout.write(`[Letter: ${nextChar}]`)
			letters.push(nextChar)
		}
		pos = nextPos
	}

	return letters
}

const print = (pos, dir, diagram) => {
	const dirs = ['^', 'v', '>', '<']
	const windowLimits = [40, 18]
	const windowY = [
		Math.max(0, Math.min(pos[1] - Math.floor(windowLimits[1]/2), diagram.length - windowLimits[1])),
		Math.min(diagram.length, Math.max(pos[1] + Math.floor(windowLimits[1]/2), windowLimits[1]))
	]
	const windowX = [
		Math.max(0, Math.min(pos[0] - Math.floor(windowLimits[0]/2), diagram[0].length - windowLimits[0])),
		Math.min(diagram[0].length, Math.max(pos[0] + Math.floor(windowLimits[0]/2), windowLimits[0]))
	]

	const xLength = windowX[1]-windowX[0]

	if (windowY[0] !== 0) {
		if (windowX[0] != 0) process.stdout.write(' ')
		process.stdout.write(new Array(xLength).join('^'))
	}
	process.stdout.write('\n')
        for (let y = windowY[0]; y < windowY[1]; y++) {
		const row = diagram[y]
		if (windowX[0] != 0) process.stdout.write('<')
		if (y != pos[1]) {
			process.stdout.write(row.substring(windowX[0], windowX[1]))
		} else {
			process.stdout.write(row.substring(windowX[0], pos[0])
				+ dirs[dir]
				+ row.substring(pos[0] + 1, windowX[1]))
		}
		if (windowX[1] !== diagram[0].length) process.stdout.write('>')
		process.stdout.write('\n')
	}
	if (windowY[1] !== diagram.length) {
		if (windowX[0] != 0) process.stdout.write(' ')
		process.stdout.write(new Array(xLength).join('v'))
	}
	process.stdout.write(`\n\n^-- pos:${pos},dir:${dir} --^\n\n`)
}

const diagram = parseInput()
const letters = loop(diagram)
console.log(`Letters: ${letters.join('')}`)
