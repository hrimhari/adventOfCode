const fs = require('fs')

var evenlyDivisible = function (line) {
	line.sort((a, b) => a - b)

	for (var lowI = 0; lowI < line.length; lowI++) {
		for (var highI = line.length - 1; highI > lowI; highI--) {
			console.log(`${line[highI]}(${highI}) % ${line[lowI]}(${lowI}) = ${line[highI] % line[lowI]}`)
			if ((line[highI] % line[lowI]) === 0) {
				var result = line[highI] / line[lowI]
				console.log(`${line[highI]} % ${line[lowI]} = 0, / = ${result}`)
				return result
			}
		}
	}
	throw new Error('No two numbers found')	
}

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
		line = line.map(item => parseInt(item))
		console.log(`Columns: ${line.length}`)
		sum += evenlyDivisible(line)
	})
	
	console.log(`Checksum: ${sum}`)
	return sum
}

var inputToArray = function(filename) {
	filename = filename || 'input.txt'
	var input = fs.readFileSync(filename, {encoding: 'utf8'})

	var inputArray = input.split('\n')
	inputArray = inputArray.filter(line => line.length != 0)

	console.log(`Input lines: ${inputArray.length}`)
	return inputArray
}

checksum(inputToArray(process.argv[2]))
