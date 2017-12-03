const fs = require('fs')

var difference = function(line) {
	if (line.length === 0) return 0

	var min = Number.MAX_SAFE_INTEGER
	var max = 0
	
	line.forEach((item) => {
		min = Math.min(min, item)
		max = Math.max(max, item)
	})

	var result = max - min
	console.log(`Difference: ${result}`)
	return result
}

var checksum = function(inputLines) {
	var sum = 0

	inputLines.forEach((line) => {
		line = line.split(/\s+/)
		console.log(`Columns: ${line.length}`)
		sum += difference(line)
	})
	
	console.log(`Checksum: ${sum}`)
	return sum
}

var inputToArray = function(filename) {
	filename = filename || 'input.txt'
	var input = fs.readFileSync(filename, {encoding: 'utf8'})

	var inputArray = input.split('\n')

	console.log(`Input lines: ${inputArray.length}`)
	return inputArray
}

checksum(inputToArray(process.argv[2]))
