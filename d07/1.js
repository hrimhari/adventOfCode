const fs = require('fs')

const addProgram = function(progWeightHolding, programs) {
	const [name, weight, holding] = progWeightHolding

	console.log(`Adding [${name},${weight},[${holding}]]`)
	programs[name] = programs[name] || {}
	programs[name].name = name
	programs[name].weight = weight
	programs[name].holding = holding.filter(name => name != '')
		.map(prog => addProgram([prog, undefined, []], programs))
		.forEach(prog => prog.heldBy = programs[name])
	console.log(`Added [${programs[name].name},${programs[name].weight},${programs[name].holding},${programs[name].heldBy && programs[name].heldBy.name}]`)
	return programs[name]
}

const findRoot = function(programs) {
	console.log(`Find root of ${Object.keys(programs).length} programs`)
	let startProgram = Object.keys(programs)[0]
	console.log(`Starting with: ${startProgram}`)
	let root = programs[startProgram]

	while (root.heldBy !== undefined) {
		console.log(`Not ${root.name}. Held by ${root.heldBy.name}`)
		root = root.heldBy
	}

	console.log(`Root: ${root.name}`)
	return root
}

const parseInput = function() {
	const programs = {}
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'}).split('\n').filter(line => line != '')

	lines.forEach(line => {
		const progWeightHolding = line.split(/\s\(|\)(?: -> )?/g)
		progWeightHolding[2] = progWeightHolding[2] || ''
		progWeightHolding[2] = progWeightHolding[2].split(/,\s/)
		addProgram(progWeightHolding, programs)
	})
	return programs
}

const programs = parseInput()
findRoot(programs)
