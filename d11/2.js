const fs = require('fs')

/*

Modelisation de matrice vers hex grid

Célules de la matrice:
1 2 3 4
5 6 7 8
9 A B C

Correspondence sur l'hex grid:
  +--+      +--+      +--+
 /    \    /    \    /    \
+  1   +--+  3   +--+      +
 \    /    \    /    \    /
  +--+  2   +--+  4   +--+
 /    \    /    \    /    \
+  5   +--+  7   +--+      +
 \    /    \    /    \    /
  +--+   6  +--+  8   +--+
 /    \    /    \    /    \
+  9   +--+  B   +--+      +
 \    /    \    /    \    /
  +--+  A   +--+  C   +--+

- Le deplacement vers 'n' ou 's' est le même que la matrice.
- Si pair:
	- Le deplacement vers 'ne' ou 'nw' équivaut a 'e' ou 'w' sur la matrice.
	- Le deplacement vers 'se' ou 'sw' est le même que la matrice.
- Si impair:
	- Le deplacement vers 'ne' ou 'nw' est le même que la matrice.
	- Le deplacement vers 'se' ou 'sw' équivaut a 'e' ou 'w' sur la matrice.

*/
const parseInput = function() {
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'})
		.replace(/\s/g, '')
		.split(',')
//	console.log(JSON.stringify(lines))
	return lines
}

const setFarthest = function(grid) {
	grid.farthest = grid.farthest || {x: grid.origin.x, y:grid.origin.y, distance: 0}
	const distance = shortestPath(grid)

	if (distance > grid.farthest.distance) {
		Object.assign(grid.farthest, grid.pos, {distance: distance})
	}
}

const setStep = function(grid) {
	grid[grid.pos.y] = grid[grid.pos.y] || []
	grid[grid.pos.y][grid.pos.x] = grid[grid.pos.y][grid.pos.x] || []
	grid[grid.pos.y][grid.pos.x].push(grid.stepNo)
	setFarthest(grid)
}

const unshiftYIfNeg = function(grid) {
	if (grid.pos.y < 0) {
		grid.unshift([])
		grid.pos.y++
		grid.posSave.y++
		grid.origin.y++
	}
}

// To keep the matrix aligned with the hex grid, width needs to change by 2.
const unshiftXIfNeg = function(grid) {
	if (grid.pos.x < 0) {
		grid.forEach(line => line.unshift([],[]))
		grid.pos.x+=2
		grid.posSave.x+=2
		grid.origin.x+=2
	}
}

const n = function(grid) {
	--grid.pos.y
	unshiftYIfNeg(grid)
}

const ne = function(grid) {
	if ((grid.pos.x % 2) == 0) {
		grid.pos.y--
		unshiftYIfNeg(grid)
	}
	grid.pos.x++
}

const nw = function(grid) {
	if ((grid.pos.x % 2) == 0) {
		grid.pos.y--
		unshiftYIfNeg(grid)
	}
	--grid.pos.x
	unshiftXIfNeg(grid)
}

const se = function(grid) {
	if ((grid.pos.x % 2) == 1) {
		grid.pos.y++
	}
	grid.pos.x++
}

const sw = function(grid) {
	if ((grid.pos.x % 2) == 1) {
		grid.pos.y++
	}
	--grid.pos.x
	unshiftXIfNeg(grid)
}

const s = function(grid) {
	grid.pos.y++
}

	
const walk = function(step, grid, skipTracking) {
	skipTracking !== true && (grid.stepNo = (grid.stepNo || 0) + 1)
	//console.log(`${grid.stepNo}: ${step}(${grid.pos.x},${grid.pos.y})(${grid.origin.x},${grid.origin.y}): ${skipTracking && 'skip tracking' || ''}`)
	eval(`${step}(grid)`)
	skipTracking !== true && setStep(grid)
}

const processPath = function(steps, grid) {
	grid.pos = {x:0, y:0}
	grid.posSave = Object.assign({}, grid.pos)
	grid.origin = Object.assign({}, grid.pos)
	setStep(grid)

	steps.forEach(step => walk(step, grid))
}

const formatPos = function(x, y, grid) {
	let value = ''

	if (grid.pos.x === x && grid.pos.y === y) {
		value = 'P'
	} else if (grid.origin.x === x && grid.origin.y === y) {
		value = 'S'
	} else if (grid[y][x] && grid[y][x].length > 0) {
		value = '' + grid[y][x][grid[y][x].length - 1]
	}

	value = value.padStart(3, ' ').padEnd(4, ' ')

	return value
}

const printEven = function(grid, y) {
	for (var x = 0; x < grid[y].length;x+=2) {
		process.stdout.write(' /    \\   ') 
	}
	process.stdout.write('\n')
	for (var x = 0; x < grid[y].length;x+=2) {
		process.stdout.write(`+ ${formatPos(x, y, grid)} +--`)
	}
	process.stdout.write('\n')
}

const printOdd = function(grid, y) {
	process.stdout.write(' \\   ')
	for (var x = 1; x < grid[y].length;x+=2) {
		process.stdout.write(' /    \\   ') 
	}
	process.stdout.write('\n  +--')
	for (var x = 1; x < grid[y].length;x+=2) {
		process.stdout.write(`+ ${formatPos(x, y, grid)} +--`)
	}
	process.stdout.write('\n')
}


const printGrid = function(grid) {
	for (let y = 0; y < grid.length; y++) {
		printEven(grid, y)
		printOdd(grid, y)
	}
}

const shortestPath = function(grid) {
	let result = 0
	Object.assign(grid.posSave, grid.pos)

	while (grid.pos.x != grid.origin.x || grid.pos.y != grid.origin.y) {
		result++
		let step = ''
		const y = grid.pos.y - grid.origin.y
		if (y < 0) {
			step = 's'
		} else if (y > 0) {
			step = 'n'
		} else {
			step += (grid.pos.x % 2 == 1)? 'n' : 's'
		}

		const x = grid.pos.x - grid.origin.x
		if (x < 0) {
			step += 'e'
		} else if (x > 0) {
			step += 'w'
		}

		//console.log(`(${x},${y}): ${step}`)
		walk(step, grid, true)
	}
	// Reset pos
	Object.assign(grid.pos, grid.posSave)
	
	return result
}

const hexGrid = [[]]
const steps = parseInput()
processPath(steps, hexGrid)
if (process.argv[2] != undefined) printGrid(hexGrid)
console.log(`Shortest: ${shortestPath(hexGrid)}`)
console.log(`Longest: ${hexGrid.farthest.distance}`)
