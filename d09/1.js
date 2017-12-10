const fs = require('fs')

let level = 0

const parseInput = function() {
	const programs = {}
	const inputName = process.argv[2] || 'input.txt'
	const stream = fs.readFileSync(inputName)
	return stream
}

const parseGarbage = function(stream) {
	console.log(`Skipping garbage`)
	for (let c = stream.next().value; c !== undefined; c = stream.next().value) {
		console.log(c)
		switch(c) {
		case '!':
			let s = stream.next().value
			console.log(`-> ${s}`)
			break
		case '>':
			console.log(`Skipped garbage`)
			return
		default:
			break
		}
	}
}

const parseGroup = function(stream, group) {
	console.log(`Entering level ${++level}`)
	group.groups = []
	for (let c = stream.next().value; c !== undefined; c = stream.next().value) {
		console.log(c)
		switch(c) {
		case '{':
			group.groups.push(parseGroup(stream, {}))
			break
		case '}':
			console.log(`Exiting level ${level--}`)
			return group
		case ',':
			break
/*
		case '!':
			let s = stream.next().value
			console.log(`-> ${s}`)
			break
*/
		case '<':
			parseGarbage(stream)
			break
		case '\n':
			break
		default:
			throw new Error(`Unexpected ${c}`)
		}
	}
	console.log('Unexpected end of stream')
	level--
	return group
}

const parseStream = function(stream, groups) {
	// Skip first opening
	stream.next()
	return parseGroup(stream, groups)
}

const bufferToGenerator = function*(buffer) {
	for (const c of buffer.entries()) {
		yield String.fromCharCode(c[1])
	}
}

const score = function(group, previous) {
	previous = previous || 0

	group.score = ++previous

	for (const subgroup of group.groups) {
		score(subgroup, previous)
	}
}

const total = function(group) {
	let value = 0

	for (const subgroup of group.groups) {
		value += total(subgroup)
	}

	value += group.score
	return value
}

const groups = {}
const stream = parseInput()
parseStream(bufferToGenerator(stream), groups)
score(groups)
//console.log(JSON.stringify(groups))
const value = total(groups)
console.log(`Total: ${value}`)
