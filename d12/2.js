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

const countGroups = function(programs) {
	const visited = {}
	const numPrograms = Object.keys(programs).length
	let numGroups = 0

	while (Object.keys(visited).length < numPrograms) {
		numGroups++
		const nextPid = Object.keys(programs)
			.find(pid => visited[pid] !== true)
		const toVisit = programs[nextPid].pipes

		while (toVisit.length > 0) {
			const visiting = toVisit.shift()
			visited[visiting] = true

			programs[visiting].pipes = programs[visiting].pipes || []
			toVisit.push(...(programs[visiting].pipes.filter(pid => visited[pid] !== true)))
		}
	}

	console.log(`Count: ${numGroups}`)
}

const programs = parseInput()
countGroups(programs)

