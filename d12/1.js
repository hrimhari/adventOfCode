const fs = require('fs')

const parseInput = function() {
	const programs = {}
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'})
		.split('\n')
		.filter(line => line != '')
		.map(line => line.split(/ <-> |, /g))
	lines.forEach(line => {
		console.log(`Line: ${JSON.stringify(line)}`)
		programs[line[0]] = {pipes: line.slice(1)}
	})
	return programs
}

const countGroupZero = function(programs) {
	const visited = {}
	const toVisit = programs['0'].pipes

	while (toVisit.length > 0) {
		const visiting = toVisit.shift()
		visited[visiting] = true

		programs[visiting].pipes = programs[visiting].pipes || []
		toVisit.push(...(programs[visiting].pipes.filter(pid => visited[pid] !== true)))
	}

	console.log(`Count: ${Object.keys(visited).length}`)
}

const programs = parseInput()
countGroupZero(programs)

