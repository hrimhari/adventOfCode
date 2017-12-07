const fs = require('fs')

const addProgram = function(progWeightHolding, programs) {
	const [name, weight, holding] = progWeightHolding

	console.log(`Adding [${name},${weight},[${holding}]]`)
	programs[name] = programs[name] || {}
	programs[name].name = name
	programs[name].weight = programs[name].weight || parseInt(weight)
	if (holding !== undefined && holding.length > 0) {
		programs[name].holding = holding.filter(name => name != '')
			.map(prog => addProgram([prog, undefined, []], programs))
		programs[name].holding.forEach(prog => prog.heldBy = programs[name])
	}
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

const computeSumWeights = function(program) {
	const sum = program.holding.map(held => computeSumWeights(held))
		.reduce((acc, value) => acc + value, 0)
	program.sumWeights = sum + program.weight

	program.holding.sort((a, b) => a.sumWeights - b.sumWeights)

	console.log(`Computed ${program.name}'s sum: ${program.weight} \
+ ${program.holding[0] && program.holding[0].sumWeights || 0} + ${program.holding[1] && program.holding[1].sumWeights || 0} + ${program.holding[2] && program.holding[2].sumWeights || 0}`)
	return program.sumWeights
}

const findWrongWeight = function(program) {
	console.log(`Checking ${program.name}'s weight: ${program.weight}/[${program.holding[0] && program.holding[0].sumWeights || 'x'}${program.holding.length > 0 && ('...' + program.holding[program.holding.length - 1].sumWeights) || ''}]`)
	if (program.holding.length === 0) {
		console.log('Not holding anybody')
		return program
	}

	const holding = program.holding

	if (holding[0].sumWeights != holding[1].sumWeights) {
		return findWrongWeight(holding[0])
	}
	if (holding[holding.length - 1].sumWeights != holding[1].sumWeights) {
		return findWrongWeight(holding[holding.length - 1])
	}
	console.log(`Holding all equal: ${holding[0].sumWeights},...,${holding[holding.length - 1].sumWeights}`)
	return program
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
const root = findRoot(programs)
computeSumWeights(root)
const wrong = findWrongWeight(root)
console.log(`Found wrong: ${wrong.name}, ${wrong.weight}, ${wrong.sumWeights}`)
const correct = wrong.heldBy.holding.find(prog => prog != wrong)
console.log(`Found correct: ${correct.name}, ${correct.weight}, ${correct.sumWeights}`)
console.log(`Right weight: ${wrong.weight + correct.sumWeights - wrong.sumWeights}`)

