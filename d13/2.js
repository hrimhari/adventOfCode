/*
Considering that the reference is always the first square, a forward-backward
trajectory on a linear path corresponds to a forward-only trajectory on a
circular path with double the steps in the middle. So:

[S][ ], [ ][S], [S][ ]
Has no middle steps.

[S][ ][ ],    [ ][S][ ],    [ ][ ][S],    [ ][S][ ],    [S][ ][ ]
Has one middle step, so it's equivalent to
[S][ ][ ][ ], [ ][S][ ][ ], [ ][ ][S][ ], [ ][ ][ ][S], [S][ ][ ][ ]

[S][ ][ ][ ],       [ ][S][ ][ ],       [ ][ ][S][ ],       [ ][ ][ ][S],       [ ][ ][S][ ],       [ ][S][ ][ ],       [S][ ][ ][ ]
Has two middle steps, so it's equivalent to
[S][ ][ ][ ][ ][ ], [ ][S][ ][ ][ ][ ], [ ][ ][S][ ][ ][ ], [ ][ ][ ][S][ ][ ], [ ][ ][ ][ ][S][ ], [ ][ ][ ][ ][ ][S], [S][ ][ ][ ][ ][ ]

Since all start at 0, the sensor will be at 0 every modulus the length of the
circular equivalent.
*/
const fs = require('fs')

const parseInput = function() {
	const layers = {}
	const inputName = process.argv[2] || 'input.txt'
	const lines = fs.readFileSync(inputName, {encoding: 'utf8'})
		.split('\n')
		.filter(line => line != '')
		.map(line => line.split(': ').map(item => parseInt(item)))
		.forEach(line => {
			layers[line[0]] = {
				length: line[1],
				circularLength: line[1] + (line[1] - 2)
			}
		})
	return layers
}

const smallestDelay = function(layers) {
	let delay
	for (delay = 0, cost = 1; cost > 0; delay++) {
		cost = cross(delay, layers)
	}
	return Math.max(delay - 1, 0)
}

const cross = function(time, layers) {
	const layerDepths = Object.keys(layers).sort((a, b) => a - b)
//	console.log(`Layers: ${layerDepths}`)
	const lastLayer = layerDepths[layerDepths.length - 1]
	let cost = 0

	for (let step = 0; step <= lastLayer; step++) {
		const layer = layers[step]
		if (!layer) continue

		const position = (time + step) % layer.circularLength
		const hit = position === 0
//		console.log(`${step} clength ${layer.circularLength} position ${position}: hit == ${hit}`)

		if (hit) {
			const hitCost = 1
			cost += hitCost
//			console.log(`Hit ${step}! hitCost=${hitCost}, new cost=${cost}`)
		}
	}
	return cost
}

const firewall = parseInput()
const delay = smallestDelay(firewall)
console.log(`Smallest delay: ${delay}`)
