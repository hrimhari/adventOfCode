const fs = require('fs')

const runMaze = function(jumpArray) {
	let offset = 0
	let steps = 0

	while (offset < jumpArray.length || offset < 0) {
		const jumpTo = jumpArray[offset]
		jumpArray[offset] += (jumpTo >= 3 ? -1 : 1)
//		console.log(`${steps}:jump=${jumpTo}:maze[${offset}]=${jumpArray[offset]}`)
		steps % 100 === 0 && console.log(`${steps}:jump=${jumpTo}:maze[${offset}]=${jumpArray[offset]}`)
		offset += jumpTo
		steps++
	}

	console.log(`${offset}>=${jumpArray.length}`)
	console.log(`Steps: ${steps}`)
}

const inputFileName = process.argv[2]||'input.txt'

const jumpArray = fs.readFileSync(inputFileName, {encoding: 'utf8'}).split('\n').filter(line => line != '').map(jump => {
//	console.log(jump)
	return parseInt(jump)
})

//console.log(jumpArray)
runMaze(jumpArray)


